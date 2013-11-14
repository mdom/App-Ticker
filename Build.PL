use Module::Build;
my $build = Module::Build->new(
    module_name => 'App::Ticker',
    license     => 'perl',
    requires    => {
        'Encode'           => 0,
        'List::MoreUtils'  => 0,
        'MIME::Lite'       => 0,
        'Mojo::ByteStream' => 0,
        'Mojo::Date'       => 0,
        'Mojo::JSON'       => 0,
        'Mojo::UserAgent'  => 0,
        'Moo'              => 0,
        'Moo::Role'        => 0,
        'Path::Tiny'       => 0,
        'Scalar::Util'     => 0,
        'strict'           => 0,
        'Try::Tiny'        => 0,
        'XML::FeedPP'      => 0,
	'File::Spec'       => '3.4'
        'Email::Date::Format' => 0,
    },
);
$build->create_build_script;
