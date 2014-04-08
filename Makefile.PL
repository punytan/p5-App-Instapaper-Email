use inc::Module::Install;
name 'App-Instapaper-Email';
all_from 'lib/App/Instapaper/Email.pm';

# requires '';

requires 'Authen::SASL';
requires 'Net::SMTP::SSL';
requires 'Email::MIME::Creator';
requires 'Email::Sender::Simple';
requires 'Email::Sender::Transport::SMTP';
requires 'Email::Simple';
requires 'Email::Simple::Creator';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'Log::Minimal';
requires 'Web::Scraper';
requires 'Config::PP';
requires 'sane';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

install_script 'bin/instapaper2email.pl';

auto_set_repository;
auto_include;
WriteAll;
