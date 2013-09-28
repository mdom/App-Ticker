package App::Ticker::Filter::FullContentRule;
use Moo;
extends 'App::Ticker::Plugin';
with 'App::Ticker::Role::DomainRule', 'App::Ticker::Role::FetchURL';

use Mojo::URL;
use Mojo::DOM;

sub process_item {
    my ( $self, $item ) = @_;
    my $rule = $self->get_rule($item);
    return if !$rule;
    return if ! exists $rule->{body};

    my $url  = $item->link;
    my $tx = $self->ua->get($url);
    if ( my $res = $tx->success ) {

        my $dom = $res->dom;
        my $html;
        if ( exists $rule->{single_page_link} ) {
            $html = $self->get_single_page($dom,$rule);
        }
        elsif ( exists $rule->{next_page_link } ) {
            $html = $self->get_single_page($dom,$rule);

        }
        else {
            $html = $self->get_body($dom,$rule);

        }

        $html = $self->resolve_link( $html, $tx->req->url );
        $item->body($html);
    }
    return;
}

sub get_multi_page {
    my ( $self, $dom, $rule ) = @_;
    my @doms;
    while ( my $url = $self->get_multi_page_link($dom,$rule) ) {
        my $tx = $self->ua->get($url);
        if ( my $res = $tx->success ) {
            $dom = $res->dom;
            my $html = $self->get_body($dom,$rule);
            push @doms, $html;
        }
    }
    return join( '', @doms );
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
    my ( $self, $dom,$rule ) = @_;
    my $url;
    for my $selector ( @{ $rule->{single_page_link} } ) {
        my $link = $dom->at($selector);
        $url = $link->attr('href');
        last if $url;
    }
    if ($url) {
        my $tx = $self->ua->get($url);
        if ( my $res = $tx->success ) {
            return $self->get_body($dom,$rule);
        }
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
