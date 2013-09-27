package App::Ticker::Filter::FullContentRule;
use Moo;
extends 'App::Ticker::Plugin';
use App::Ticker::Filter::FullContentRule::Rule;
use Path::Tiny;

has rules => (
    is      => 'rw',
    default => sub { {} },
    coerce  => sub {
        my $arg = shift;
        if ( ref($arg) eq 'HASH' ) {
            my %rules;
            for my $domain ( keys %$arg ) {
                $rules{$domain} = App::Ticker::Filter::FullContentRule::Rule->new( $arg->{$domain} );
            }
            return \%rules;
        }
	else {
		die "rules has to be an hash reference\n";
	}
    }
);

has 'rule_dir' => (
    is      => 'rw',
    default => 'ftr-site-config',
    coerce  => sub {
        ref( $_[0] ) or path( $_[0] );
    }
);

sub get_rule {
    my ( $self, $url ) = @_;
    my $host     = Mojo::URL->new($url)->host;
    my @segments = ($host);
    my @parts    = split( /\./, $host );
    shift @parts;
    while ( @parts > 1 ) {
        push @segments, join( '.', @parts );
        shift @parts;
    }
    my $rule_file;
    for my $segment (@segments) {
        if ( exists $self->rules->{$segment} ) {
            return $self->rules->{$segment};
        }
    }

    for my $segment (@segments) {
        my $file = $self->rule_dir->child("$segment.txt");
        if ( $file->exists ) {
            $rule_file = $file;
            last;
        }
    }
    return if !$rule_file;
    my $yaml = YAML::Tiny->rean($rule_file);
    return if !$yaml;
    $self->rules->{ $rule_file->basename } = $yaml->[0];
    return $yaml->[0];
}

sub process_item {
    my ( $self, $item ) = @_;
    my $url = $item->link;
    my $rule = $self->get_rule($url);
    my $content = $rule->apply($url);
    $item->body($content);
    return;
}

1;
