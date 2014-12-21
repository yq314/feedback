#!/usr/bin/env perl
use strict;

use CGI qw(:standard);
use JSON;
use MIME::Lite;
use MIME::Base64;

my $cgi = new CGI;

my $data = $cgi->param('POSTDATA');

my $obj = decode_json($data);
$obj->{img} =~ s/^data:image\/png;base64,//;
$obj->{note} =~ s/\n/<br>/g;
my $cookie = $obj->{browser}->{cookieEnabled} ? 'Yes' : 'No';
my $plugins = join(', ', @{$obj->{browser}->{plugins}});

my $email_content = <<_EMAIL_;
<html>
<body>
    <p><b>URL</b>: <a href="$obj->{url}">$obj->{url}</a></p>
    <p>
        <b>Browser</b>:<br/> 
        <u>Platform</u>: $obj->{browser}->{platform}<br/>
        <u>UserAgent</u>: $obj->{browser}->{userAgent}<br/>
        <u>Cookie Enabled</u>: $cookie<br/>
        <u>Plugins</u>: $plugins
    </p>
    <p><b>Note</b>:<br/> $obj->{note}</p>
    <p><b>Screenshot</b>:<br/> <img src="cid:image_1" alt="inline image" /></p>
</body>
</html>
_EMAIL_

my $msg = MIME::Lite->new(
    From            => 'Visitor<visitor@test.url>',
    To              => 'feedback@test.url',
    Subject         => 'A feedback received from customer',
    Type            =>'multipart/related'
);

$msg->attach(
    Type => 'text/html',
    Data => $email_content,
    Encoding => 'quoted-printable'
);

$msg->attach(
    Encoding => 'base64',
    Type => 'image/png',
    Data => decode_base64($obj->{img}),
    Id => 'image_1'
);

$msg->send();

print $cgi->header(-type => 'application/json');
print '{"result":"OK"}';
