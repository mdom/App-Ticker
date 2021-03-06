package App::Ticker::Role::FetchURL;
use Moo::Role;
use Mojo::UserAgent;

has 'ua' => (
    is      => 'lazy',
    handles => { get_url => 'get' },
);

sub _build_ua {
    return Mojo::UserAgent->new(
        max_redirects   => 5,
        request_timeout => 10,
    );
}

1;
