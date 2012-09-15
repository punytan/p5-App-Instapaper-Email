#!/usr/bin/env perl

use sane;
use Config::PP;
use App::Instapaper::Email;

$Config::PP::DIR = shift || "$ENV{HOME}/.ppconfig/instapaper2email";

my $email = config_get 'email';
my $sasl  = config_get 'google.com';
my $instapaper = config_get 'instapaper.com';

my $app = App::Instapaper::Email->new(
    to   => $email->{to},
    from => $email->{from},
    username => $instapaper->{username},
    password => $instapaper->{password},
    sasl_username => $sasl->{username},
    sasl_password => $sasl->{password},
);

$app->run;

__END__

