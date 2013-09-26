package Ticker::Plugin::HTTPCache;
use Moo::Role;
use Path::Tiny;
use Mojo::ByteStream 'b';
use Mojo::JSON;
use Mojo::Date;

around 'get_feed' => sub {
    my ( $orig, $self, $url, $header ) = @_;
    $header = {} if not defined $header;

    my $json      = Mojo::JSON->new();
    my $cache_dir = $self->workdir->child('http_cache');
    $cache_dir->mkpath();
    my $hash_file = $cache_dir->child( b($url)->md5_sum );

    my $cache_info;
    if ( $hash_file->exists ) {
        $cache_info = $json->decode( $hash_file->slurp );
    }

    $header->{'If-None-Match'} = $cache_info->{etag}
      if $cache_info->{etag};
    $header->{'If-Modified-Since'} = $cache_info->{timestamp}
      if $cache_info->{timestamp};

    my ( $feed, $res ) = $self->$orig( $url, $header );

    $cache_info->{etag} = $res->headers->etag || '';

    if ( my $date = $res->headers->last_modified ) {
        $cache_info->{timestamp} = $date;
    }
    else {
        $cache_info->{timestamp} = Mojo::Date->new( time() )->to_string;
    }

    $hash_file->spew( $json->encode($cache_info) );

    return $feed, $res;
};

1;
