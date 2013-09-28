package App::Ticker::Filter::StripTags;
use Moo;
extends 'App::Ticker::Plugin';
with 'App::Ticker::Role::DomainRule';

use Mojo::DOM;

sub process_item {
    my ($self,$item) = @_;
    my $rule  = $self->get_rule($item);
    return if ! $rule;

    my $dom = Mojo::DOM->new($item->body);

    if ( exists $rule->{strip}  ) {
        for my $strip ( @{ $rule->{strip} } ) {
            $dom->find($strip)->pluck('remove');
        }
    }
    if ( exists $rule->{replace} ) {
        for my $replace ( @{ $rule->{replace} } ) {
            $dom->find( $replace->[0] )->pluck( 'replace', $replace->[1] );
        }
    }
    $item->body( $dom->to_xml );
    return;
}

1;
