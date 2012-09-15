package App::Instapaper::Email;
use strict;
use warnings;
our $VERSION = '0.02';

use Web::Scraper;
use LWP::UserAgent;
use Log::Minimal;
use Sys::Hostname;
use Email::Sender::Simple 'sendmail';
use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SMTP;
use Email::MIME::Creator;

$Log::Minimal::AUTODUMP = 1;

our $InstapaperURL = {
    unread => 'http://www.instapaper.com/u',
    liked  => 'http://www.instapaper.com/liked',
    login  => 'http://www.instapaper.com/user/login',
};

sub new {
    my ($class, %args) = @_;

    my $instapaper = {
        username => $args{username},
        password => $args{password},
    };

    my $sasl = {
        username => $args{sasl_username},
        password => $args{sasl_password},
    };

    my $ua = LWP::UserAgent->new(
        agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:15.0) Gecko/20100101 Firefox/15.0.1',
        cookie_jar   => {},
        max_redirect => 0,
    );

    my $to      = $args{to};
    my $from    = $args{from} || sprintf "%s@%s", getlogin(), hostname();
    my $wait    = $args{wait} || 1;
    my $dry_run = $args{dry_run};

    bless {
        to      => $to,
        from    => $from,
        wait    => $wait,
        sasl    => $sasl,
        dry_run => $dry_run,
        instapaper => $instapaper,
        useragent  => $ua,
    }, $class;
}

sub useragent {
    my $self =  shift;
    sleep $self->{wait};
    $self->{useragent}
}

sub run {
    my ($self, %args) = @_;

    infof "authenticating";
    $self->authenticate;

    $self->useragent->max_redirect(1);

    my $likes = $self->fetch_likes;
    for my $item (@$likes) {
        next unless $item->{url};

        my $url = $item->{url};
        infof "process: %s", $url;

        if ($self->{dry_run}) {
            $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
        }
        $self->send($item);

        next if $self->{dry_run};
        $self->unlike($item);
    }

    if ($self->{dry_run}) {
        debugff [ Email::Sender::Simple->default_transport->deliveries ];
    }
}

sub authenticate {
    my $self = shift;

    my $try = $self->useragent->get($InstapaperURL->{unread});
    return if $try->code == 200;

    my $login = $self->useragent->post(
        $InstapaperURL->{login}, {
            username => $self->{instapaper}{username},
            password => $self->{instapaper}{password},
        }
    );

    debugff $login;
    if ($login->code == 200) {
        return;
    } else {
        croakf "[instapaper] Failed to login: %s", $login->code;
    }
}

sub fetch_likes {
    my $self = shift;

    my $res = $self->useragent->get($InstapaperURL->{liked});

    unless ($res->is_success) {
        croakf "[instapaper] Failed fetching like: %s", $res->code;
    }

    my $scraper = scraper {
        process ".tableViewCell", "bookmarks[]" => scraper {
            process ".titleRow a", url => '@href';
            process ".likeBox  a", like_toggle => '@href';
        };
    };

    my $parsed = $scraper->scrape($res);
    return $parsed->{bookmarks};
}

sub unlike {
    my ($self, $item) = @_;
    my $res = $self->useragent->get($item->{like_toggle});

    unless ($res->is_success) {
        warnf "failed unliking %s, %s", $res->code, $res->decoded_content;
        croakf $res->headers;
    }
}

sub send {
    my ($self, $item) = @_;

    my $email = Email::Simple->create(
        header => [
            From    => $self->{from},
            To      => $self->{to},
            Subject => "no subject",
        ],
        body => $item->{url},
    );

    my $transport = Email::Sender::Transport::SMTP->new({
        ssl  => 1,
        host => 'smtp.gmail.com',
        port => 465,
        sasl_username => $self->{sasl}{username},
        sasl_password => $self->{sasl}{password},
    });

    sendmail( $email, { transport => $transport } );
}

1;
__END__

=head1 NAME

App::Instapaper::Email -

=head1 SYNOPSIS

  use App::Instapaper::Email;

=head1 DESCRIPTION

App::Instapaper::Email is

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
