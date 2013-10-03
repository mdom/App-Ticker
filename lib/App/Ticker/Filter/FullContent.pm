package App::Ticker::Filter::FullContent;
use Moo;
extends 'App::Ticker::Plugin';
with 'App::Ticker::Role::DomainRule', 'App::Ticker::Role::FetchURL';

use Mojo::URL;
use Mojo::DOM;

sub process_item {
    my ( $self, $item, $cb ) = @_;
    my $rule = $self->get_rule($item);
    if ( $rule and exists $rule->{body} ) {
        my $url = $item->link;
        $self->ua->get(
            $url,
            sub {
                my ( $ua, $tx ) = @_;
                if ( my $res = $tx->success ) {
                    my $dom = $res->dom;
                    my $html;
                    my $cb = sub { 
                        my $item = shift;
                        $self->resolve_link( $item, $tx->req->url );
                        $cb->($item);
                    };
                    if ( exists $rule->{single_page_link} ) {
                        $self->get_single_page( $dom, $rule, $item, $cb );
                    }
                    elsif ( exists $rule->{next_page_link} ) {
                        $self->get_multi_page( $dom, $rule, $item, $cb );
                    }
                    else {
                        my $body = $self->get_body( $dom, $rule, $item );
                        $item->body($body);
                        $cb->($item);

                    }
                }
       });
    } else {
        $cb->($item);
    }
    return;
}

sub get_multi_page {
    my ( $self, $dom, $rule, $item, $cb ) = @_;
    if ( my $url = $self->get_multi_page_link( $dom, $rule ) ) {
        $self->ua->get(
            $url,
            sub {
                my ( $ua, $tx ) = @_;
                if ( my $res = $tx->success ) {
                    $dom = $res->dom;
                    my $body = $self->get_body( $dom, $rule );
                    $item->body( $item->body . $body );
                    $self->get_multi_page( $dom, $rule, $item, $cb );
                }
            }
        );
    }
    else {
        $cb->($item);
    }
    return;
}

sub get_multi_page_link {
    my ( $self, $dom, $rule ) = @_;
    my $url;
    for my $selector ( @{ $rule->{next_page_link} } ) {
        my $link = $dom->at($selector);
        next if !$link;
        my $url = $link->attr('href');
        last if $url;
    }
    return $url;
}

sub get_single_page {
    my ( $self, $dom, $rule, $item, $cb ) = @_;
    my $url;
    for my $selector ( @{ $rule->{single_page_link} } ) {
        my $link = $dom->at($selector);
        $url = $link->attr('href');
        last if $url;
    }
    if ($url) {
        $self->ua->get(
            $url,
            sub {
                my ( $ua, $tx ) = @_;
                if ( my $res = $tx->success ) {
                    my $body = $self->get_body( $dom, $rule );
                    $item->body($body);
                    $cb->($item);
                }
                return;
            }
        );
    }
    else {
        $cb->($item);
    }
    return;
}

sub get_body {
    my ( $self, $dom, $rule ) = @_;
    if ( @{ $rule->{body} } ) {
        for my $body ( @{ $rule->{body} } ) {
            my $collection = $dom->find($body);
            if ($collection) {
                $dom = Mojo::DOM->new( $collection->join('')->to_string );
                last;
            }
        }
    }
    return $dom->to_xml;
}

sub resolve_link {
    my ( $self, $item, $base ) = @_;
    $base = Mojo::URL->new($base);
    my $dom   = Mojo::DOM->new($item->body);
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
    $item->body($dom->to_xml);
    return;
}

1;
