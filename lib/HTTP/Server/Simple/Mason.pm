package HTTP::Server::Simple::Mason;
use base qw/HTTP::Server::Simple/;
use strict;
our $VERSION = '0.01';

=head1 NAME

HTTP::Server::Simple::Mason - An abstract baseclass for a standalone mason server


=head1 VERSION

This document describes HTTP::Server:Simple::Mason version 0.0.1


=head1 SYNOPSIS


	my $server = MyApp::Server->new();
	
	$server->run;
	
	package MyApp::Server;
	use base qw/HTTP::Server::Simple::Mason/;
	
	sub handler_config {
	    my $self = shift;
	    return ( $self->SUPER::handler_config, comp_root => '/tmp/mason-pages' );
	}

    1;

=head1 DESCRIPTION


=head1 INTERFACE

See L<HTTP::Server::Simple> and the documentation below.

=cut



use HTML::Mason::CGIHandler;

sub handler {
    my $self = shift;
    $self->{'handler'} ||= $self->new_handler;
    return $self->{'handler'};
}

sub handle_request {
    my $self = shift;
    my $cgi  = shift;
    if (
        ( !$self->handler->interp->comp_exists( $cgi->path_info ) )
        && (
            $self->handler->interp->comp_exists(
                $cgi->path_info . "/index.html"
            )
        )
      )
    {
        $cgi->path_info( $cgi->path_info . "/index.html" );
    }

            print <<EOF;
HTTP/1.0 200 OK
Content-Type: text/html
EOF

    eval { $self->handler->handle_cgi_object($cgi); };

}

sub new_handler {
    my $self    = shift;
    my $handler = HTML::Mason::CGIHandler->new( $self->handler_config, @_ );

    $handler->interp->set_escape(
        h => \&HTTP::Server::Simple::Mason::escape_utf8 );
    $handler->interp->set_escape(
        u => \&HTTP::Server::Simple::Mason::escape_uri );
    return ($handler);
}

sub handler_config {
    (
        default_escape_flags => 'h',

        # Turn off static source if we're in developer mode.
        autoflush => 0
    );
}

# {{{ escape_utf8

=head2 escape_utf8 SCALARREF

does a css-busting but minimalist escaping of whatever html you're passing in.

=cut

sub escape_utf8 {
    my $ref = shift;
    my $val = $$ref;
    use bytes;
    $val =~ s/&/&#38;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\(/&#40;/g;
    $val =~ s/\)/&#41;/g;
    $val =~ s/"/&#34;/g;
    $val =~ s/'/&#39;/g;
    $$ref = $val;
    Encode::_utf8_on($$ref);

}

# }}}

# {{{ escape_uri

=head2 escape_uri SCALARREF

Escapes URI component according to RFC2396

=cut

use Encode qw();

sub escape_uri {
    my $ref = shift;
    $$ref = Encode::encode_utf8($$ref);
    $$ref =~ s/([^a-zA-Z0-9_.!~*'()-])/uc sprintf("%%%02X", ord($1))/eg;
    Encode::_utf8_on($$ref);
}

# }}}



=head1 CONFIGURATION AND ENVIRONMENT

For most configuration, see L<HTTP::Server::Simple>.

You can (and must) configure your mason CGI handler by subclassing this module and overriding
the subroutine 'handler_config'. It's most important that you set a component root (where your pages live)
by adding 

    comp_root => '/some/absolute/path'



=head1 DEPENDENCIES


L<HTTP::Server::Simple>
L<HTML::Mason>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS


Please report any bugs or feature requests to
C<bug-http-server-simple-mason@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Jesse Vincent C<< <jesse@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2001-2005, Jesse Vincent  C<< <jesse@bestpractical.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut


1;