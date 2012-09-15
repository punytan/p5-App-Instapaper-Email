use inc::Module::Install;
name 'App-Instapaper-Email';
all_from 'lib/App/Instapaper/Email.pm';

# requires '';

requires 'Email::MIME::Creator';
requires 'Email::Sender::Simple';
requires 'Email::Sender::Transport::SMTP';
requires 'Email::Simple';
requires 'Email::Simple::Creator';
requires 'LWP::UserAgent';
requires 'Log::Minimal';
requires 'Web::Scraper';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
