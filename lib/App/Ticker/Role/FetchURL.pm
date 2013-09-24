package App::Ticker::Role::FetchURL;
use Moo::Role;

has 'ua' => (
    is      => 'lazy',
    handles => { get_url => 'get' },
);

sub _build_ua {
    return Mojo::UserAgent->new(
        max_redirects => 5,
        timeout       => 10
    );
}

1;
