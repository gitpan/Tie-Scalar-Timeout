package Tie::Scalar::Timeout;

#
# $Id: Timeout.pm,v 1.2 2000/11/08 13:57:28 marcel Exp $
#
# $Log: Timeout.pm,v $
# Revision 1.2  2000/11/08 13:57:28  marcel
# Added documentation
#
# Revision 1.1.1.1  2000/11/08 13:16:50  marcel
# First import.
#
#

require 5.005_62;
use strict;
use warnings;
use Tie::Scalar;
use Time::Local;

our @ISA = qw(Tie::Scalar);
(our $VERSION) = '$Revision: 1.2 $' =~ /([\d.]+)/;

sub TIESCALAR {
	my $class = shift;
	my $self = {
	    VALUE    => undef,
	    EXPIRES  => '+1d',
	    POLICY   => undef,
	    NUM_USES => -1,
	    @_,
	};
	$self->{EXPIRY_TIME} = _expire_calc($self->{EXPIRES});
	$self->{NUM_USES_ORIG} = $self->{NUM_USES};
	return bless $self, $class;
}

sub FETCH {
	my $self = shift;

	# if num_uses isn't set or set to a negative value, it won't
	# influence the expiry process

	if (($self->{NUM_USES} == 0) ||
	   (time >= $self->{EXPIRY_TIME})) {
	   	# policy can be a coderef or a plain value
		return &{ $self->{POLICY} } if ref($self->{POLICY}) eq 'CODE';
		return $self->{POLICY};
	}
	$self->{NUM_USES}-- if $self->{NUM_USES} > 0;
	return $self->{VALUE};
}

sub STORE {
	my $self = shift;
	$self->{VALUE} = shift;

	# reset expiry time and number of uses

	$self->{EXPIRY_TIME} = _expire_calc($self->{EXPIRES});
	$self->{NUM_USES} = $self->{NUM_USES_ORIG};
}

# This routine was nicked and adapted from CGI.pm. It should probably go
# into a separate module.  This internal routine creates an expires time
# exactly some number of hours from the current time.  It incorporates
# modifications from Mark Fisher.

sub _expire_calc {
	my $time = shift;
	my %mult = (
	    's'=>1,
	    'm'=>60,
	    'h'=>60*60,
	    'd'=>60*60*24,
	    'M'=>60*60*24*30,
	    'y'=>60*60*24*365);
	# format for time can be in any of the forms...
	# "now" -- expire immediately
	# "+180s" -- in 180 seconds
	# "+2m" -- in 2 minutes
	# "+12h" -- in 12 hours
	# "+1d"  -- in 1 day
	# "+3M"  -- in 3 months
	# "+2y"  -- in 2 years
	# "-3m"  -- 3 minutes ago(!)
	# If you don't supply one of these forms, we assume you are
	# specifying the date yourself
	my $offset;
	# if (!$time || (lc($time) eq 'now')) {
	if (lc($time) eq 'now') {
		$offset = 0;
	} elsif ($time =~ /^(\d\d?)-(\w{3})-(\d{4}) (\d\d?):(\d\d?):(\d\d?)/){
		require Time::Local;   # don't use unless necessary
		my ($mday, $monthname, $year, $hours, $min, $sec) =
		    ($1, $2, $3, $4, $5, $6);
		my $month = {
		    jan =>  0,
		    feb =>  1,
		    mar =>  2,
		    apr =>  3,
		    may =>  4,
		    jun =>  5,
		    jul =>  6,
		    aug =>  7,
		    sep =>  8,
		    oct =>  9,
		    nov => 10,
		    dec => 11,
		} -> { lc $monthname };
		$year -= 1900;
		return Time::Local::timelocal_nocheck
		    ($sec, $min, $hours, $mday, $month, $year)
	} elsif ($time =~ /^\d+/) {
		return $time;
	} elsif ($time =~ /^([+-]?(?:\d+|\d*\.\d*))([mhdMy]?)/) {
		$offset = ($mult{$2} || 1)*$1;
	} else {
		return $time;
	}
	return time + $offset;
}

1;
__END__

=head1 NAME

Tie::Scalar::Timeout - Scalar variables that time out

=head1 SYNOPSIS

  use Tie::Scalar::Timeout;
  
  tie my $k, 'Tie::Scalar::Timeout', EXPIRES => '+2s';
  
  $k = 123;
  sleep(3);
  # $k is now undef
  
  tie my $m, 'Tie::Scalar::Timeout', NUM_USES => 3, VALUE => 456;
  
  tie my $n, 'Tie::Scalar::Timeout', VALUE => 987, NUM_USES => 1,
      POLICY => 777;
  
  tie my $p, 'Tie::Scalar::Timeout', VALUE => 654, NUM_USES => 1,
      POLICY => \&expired;
  sub expired { $is_expired++ }

=head1 DESCRIPTION

This module allows you to tie a scalar variable whose value will be reset
(subject to an expiry policy) after a certain time and/or a certain number
of uses. One possible application for this module might be to time out
session variables in mod_perl programs.

When tying, you can specify named arguments in the form of a hash. The
following named parameters are supported:

=over 4

=item C<EXPIRES>

Use C<EXPIRES> to specify an interval or absolute time after which the
value will be reset. (Technically, the value will still be there, but the
module's FETCH sub will return the value as dictated by the expiry policy.)

Values for the C<EXPIRES> field are modelled after Netscape's cookie
expiration times. Except, of course, that negative values don't really make
sense in a universe with linear, one-way time. The following forms are all
valid for the C<EXPIRES> field:

    +30s                    30 seconds from now
    +10m                    ten minutes from now
    +1h                     one hour from now
    +3M                     in three months
    +10y                    in ten years time
    25-Apr-2001 00:40:33    at the indicated time & date

Assigning a value to the variable causes C<EXPIRES> to be reset to the
original value.

=item C<VALUE>

Using the C<VALUE> hash key, you can specify an initial value for the
variable.

=item C<NUM_USES>

Alternatively or in addition to C<EXPIRES>, you can also specify a maximum
number of times the variable may be read from before it expires. If both
C<EXPIRES> and C<NUM_USES> are set, the variable will expire when either
condition becomes true. If C<NUM_USES> isn't set or set to a negative
value, it won't influence the expiry process.

Assigning a value to the variable causes C<NUM_USES> to be reset to the
original value.

=item C<POLICY>

The expiration policy determines what happens to the variable's value when
it expires. If you don't specify a policy, the variable will be C<undef>
after it has expired. You can specify either a scalar value or a code
reference as the value of the C<POLICY> parameter. If you specify a scalar
value, that value will be returned after the variable has expired. Thus,
the default expiration policy is equivalent to

    POLICY => undef

If you specify a code reference as the value of the C<POLICY> parameter,
that code will be called when the variable value is C<FETCH()>ed after it
has expired. This might be used to set some other variable, or reset the
variable to a different value, for example.

=back

=head1 BUGS

None known so far. If you find any bugs or oddities, please do tell me
about them.

=head1 AUTHOR

Marcel GrE<uuml>nauer <marcel@codewerk.com>

=head1 COPYRIGHT

Copyright 2000 Marcel GrE<uuml>nauer. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tie::Scalar(3pm).

=cut
