# http://help.fivefilters.org/customer/portal/articles/223153-site-patterns
# https://github.com/fivefilters/ftr-site-config

package App::Ticker::Filter::FullContentRule::Rule;
use Moo;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::DOM;
use YAML::Tiny;

has 'useragent' => (
    is      => 'rw',
    default => sub {
        Mojo::UserAgent->new(
            max_redirects => 5,
            timeout       => 10
        );
    },
);

for my $opt (
    qw(body strip replace single_page_link single_page_link_in_feed next_page_link)
  )
{
    has $opt => ( is => 'rw', default => sub { [] } );
}

sub apply {
    my ( $self, $url ) = @_;
    my $tx = $self->useragent->get($url);
    if ( my $res = $tx->success ) {

        my $dom = $res->dom;
        my $html;
        if ( @{ $self->single_page_link } ) {
            $html = $self->get_single_page($dom);
        }
        elsif ( @{ $self->next_page_link } ) {
            $html = $self->get_single_page($dom);

        }
        else {
            $html = $self->filter_dom($dom);

        }

        $html = $self->resolve_link( $html, $tx->req->url );
        return $html;
    }
    return;
}

sub get_multi_page {
    my ( $self, $dom ) = @_;
    my @doms;
    while ( my $url = $self->get_multi_page_link($dom) ) {
        my $tx = $self->useragent->get($url);
        if ( my $res = $tx->success ) {
            $dom = $res->dom;
	    my $html = $self->filter_dom($dom);
            push @doms, $html;
        }
    }
    return join('',@doms);
}

sub get_multi_page_link {
    my ( $self, $dom ) = @_;
    my $url;
    for my $selector ( @{ $self->next_page_link } ) {
        my $link = $dom->at($selector);
        next if !$link;
        my $url = $link->attr('href');
        last if $url;
    }
    return $url;
}

sub get_single_page {
    my ( $self, $dom ) = @_;
    my $url;
    for my $selector ( @{ $self->single_page_link } ) {
        my $link = $dom->at($selector);
        $url = $link->attr('href');
        last if $url;
    }
    if ($url) {
        my $tx = $self->useragent->get($url);
        if ( my $res = $tx->success ) {
            return $self->filter_dom($dom);
        }
    }
    return;
}

sub filter_dom {
    my ( $self, $dom ) = @_;
    if ( @{ $self->body } ) {
        for my $body ( @{ $self->body } ) {
            my $collection = $dom->find($body);
            if ($collection) {
                $dom = Mojo::DOM->new( $collection->join('')->to_string );
                last;
            }
        }
    }
    if ( @{ $self->strip } ) {
        for my $strip ( @{ $self->strip } ) {
$DB::single = 1;
            $dom->find($strip)->pluck('remove');
        }
    }
    if ( @{ $self->replace } ) {
        for my $replace ( @{ $self->replace } ) {
            $dom->find( $replace->[0] )->pluck( 'replace', $replace->[1] );
        }
    }
    return $dom->to_xml;
}

sub resolve_link {
    my ( $self, $html, $base ) = @_;
    $base = Mojo::URL->new($base);
    my $dom   = Mojo::DOM->new($html);
    my %types = (
        a   => 'href',
        img => 'src',
    );
    for my $element ( $dom->find( join( ',', keys %types ) )->each ) {
        my $attr = $types{ $element->type };
        my $url  = Mojo::URL->new( $element->attr($attr) );
        next if $url->is_abs;
        $element->attr( $attr => $url->base($base)->to_abs );
    }
    return $dom->to_xml;
}

1;
