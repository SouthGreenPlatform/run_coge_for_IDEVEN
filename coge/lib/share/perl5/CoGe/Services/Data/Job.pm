package CoGe::Services::Data::Job;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Asset::File;
#use IO::Compress::Gzip 'gzip';
use Data::Dumper;
use File::Basename qw( basename );
use File::Spec::Functions qw( catdir catfile );
use CoGeX;
use CoGe::Services::Auth;
use CoGe::Accessory::Web qw(url_for);
use CoGe::Accessory::Jex;
use CoGe::Accessory::TDS;
use CoGe::Core::Storage qw( get_workflow_paths get_workflow_results );
use CoGe::Factory::RequestFactory;
use CoGe::Factory::PipelineFactory;

sub add {
    my $self = shift;
    my $payload = $self->req->json;
    #print STDERR 'payload: ', Dumper $payload, "\n";
    #print STDERR 'req: ', Dumper $self->req, "\n";

    # Authenticate user and connect to the database
    my ($db, $user, $conf) = CoGe::Services::Auth::init($self);

    # User authentication is required
    unless (defined $user) {
        return $self->render(json => {
            error => { Auth => "Access denied" }
        });
    }

    # Create request and validate the required fields
    my $jex = CoGe::Accessory::Jex->new( host => $conf->{JOBSERVER}, port => $conf->{JOBPORT} );
    my $request_factory = CoGe::Factory::RequestFactory->new(db => $db, user => $user, jex => $jex); #FIXME why jex here?
    my $request_handler = $request_factory->get($payload);
    unless ($request_handler and $request_handler->is_valid) {
        return $self->render(json => {
            error => { Invalid => "Invalid request" }
        });
    }

    # Check users permissions to execute the request
    unless ($request_handler->has_access) {
        return $self->render(json => {
            error => { Auth => "Request denied" }
        });
    }

    # Create pipeline to execute job
    my $pipeline_factory = CoGe::Factory::PipelineFactory->new(conf => $conf, user => $user, jex => $jex, db => $db);
    my $workflow = $pipeline_factory->get($payload);
    unless ($workflow) {
        return $self->render(json => {
            error => { Error => "Failed to generate pipeline" }
        });
    }
    my $response = $request_handler->execute($workflow);
    
    # Get tiny link #FIXME should this be moved client-side?
    if ($response->{success}) {
        # Get tiny URL
        my ($page, $link);
        if ($payload->{requester}) { # request is from web page - external API requests will not have a 'requester' field
            $page = $payload->{requester}->{page};
            if ($page) { 
                $page = $payload->{requester}->{page};
                $link = CoGe::Accessory::Web::get_tiny_link( url => $conf->{SERVER} . $page . "?wid=" . $workflow->id );
                $response->{site_url} = $link if $link;
            }
        }
        
        # Log job submission
        CoGe::Accessory::Web::log_history(
            db          => $db,
            workflow_id => $workflow->id,
            user_id     => $user->id,
            page        => ($page ? $page : "API"),
            description => $workflow->name,
            link        => ($link ? $link : '')
        );
    }

    return $self->render(json => $response);
}

sub fetch {
    my $self = shift;
    my $id = $self->stash('id');

    # Authenticate user and connect to the database
    my ($db, $user, $conf) = CoGe::Services::Auth::init($self);

    # User authentication is required
    unless (defined $user) {
        $self->render(json => {
            error => { Auth => "Access denied" }
        });
        return;
    }

    # Get job status from JEX
    my $jex = CoGe::Accessory::Jex->new( host => $conf->{JOBSERVER}, port => $conf->{JOBPORT} );
    my $job_status = $jex->get_job($id);
    unless ($job_status) {
        $self->render(json => {
            error => { Error => "Item not found" }
        });
        return;
    }

#    unless ($job_status->{status} =~ /completed|running/i) {
#        $self->render(json => {
#            id => int($id),
#            status => $job_status->{status}
#        });
#        return;
#    }

    # TODO COGE-472: add read from "debug.log" in results path if JEX no longer has the log in memory

    # Add tasks (if any)
    my @tasks;
    foreach my $task (@{$job_status->{jobs}}) {
        my $t = {
            started => $task->{started},
            ended => $task->{ended},
            elapsed => $task->{elapsed},
            description => $task->{description},
            status => $task->{status},
            log => undef
        };

        if (defined $task->{output}) {
            foreach (split(/\\n/, $task->{output})) {
                #print STDERR $_, "\n";
                next unless ($_ =~ /^'?log\: /);
                $_ =~ s/^'?log\: //;
                $t->{log} .= $_ . "\n";
            }
        }

        push @tasks, $t;
    }

    # Add results (if any)
    # mdb removed 2/27/15 for load_experiment2
#    my ( undef, $result_dir ) = get_workflow_paths( $user->name, $id );
#    my @results;
#    if (-r $result_dir) {
#        # Get list of result files in results path
#        opendir(my $fh, $result_dir);
#        foreach my $file ( readdir($fh) ) {
#            my $fullpath = catfile($result_dir, $file);
#            next unless -f $fullpath;
#
#            my $name = basename($file);
#            push @results, {
#                type => 'http',
#                name => $name,
#                path => url_for('api/v1/jobs/'.$id.'/results/'.$name,
#                    username => $user->name
#                ) # FIXME move api path into conf file ...?
#            };
#        }
#        closedir($fh);
#    }

    my $results = get_workflow_results($user->name, $id);

    $self->render(json => {
        id => int($id),
        status => $job_status->{status},
        tasks => \@tasks,
        results => $results
    });
}

#sub results { #TODO remove this, no longer necessary in load_experiment2
#    my $self = shift;
#    my $id = $self->stash('id');
#    my $name = $self->stash('name');
#    my $format = $self->stash('format');
#
#    # Authenticate user and connect to the database
#    my ($db, $user, $conf) = CoGe::Services::Auth::init($self);
#
#    # User authentication is required
#    unless (defined $user) {
#        $self->render(json => {
#            error => { Auth => "Access denied" }
#        });
#        return;
#    }
#
#    $name = "$name.$format" if $format;
#    my ($staging_dir, $result_dir) = get_workflow_paths($user->name, $id);
#    my $result_file = catfile($result_dir, $name);
#
#    unless (-r $result_file) {
#        $self->render(json => {
#            error => { Error => "Item not found" }
#        });
#        return;
#    }
#
#    # Either download the file or display the results
#    if ($name eq "1") {
#        my $pResult = CoGe::Accessory::TDS::read($result_file);
#        $self->render(json => $pResult);
#    } 
#    else {
#        $self->res->headers->content_disposition("attachment; filename=$name;");
#        $self->res->content->asset(Mojo::Asset::File->new(path => $result_file));
#        $self->rendered(200);
#    }
#}

1;
