#!/usr/bin/env perl
use strict;
use warnings;

# Non-core dependencies
use JSON::Tiny qw(decode_json);

=head1 NAME

dogmeta.pl - Compile Dog metatemplates into Yip templates.

=head1 SYNOPSIS

  ./dogmeta.pl -date datestr.json < template.meta > template.tmpl

=head1 DESCRIPTION

Given a Dog metatemplate and a JSON file defining the datetime format,
compile a Yip template using that given datetime format.

This preprocessor only is required for Dog templates that end with the
extension C<.meta> though no harm will result if it is run on Dog
templates that end with the extension C<.tmpl> (in that case, the
template will just be output as-is).

Dog metatemplate files are processed line by line.  Lines that do not
begin immediately with a grave accent character are sent to output
as-is.  Lines that begin immediately with a grave accent character are
metatemplate lines.  If the line is blank apart from the grave accent or
there is a space or tab immediatley after the grave accent, the
metatemplate line is a comment that is discarded and not included in
output.  If the line contains grave accent, an uppercase C<D> and then
optional whitespace, the line is replaced with the compiled datetime
format.  Any other type of line beginning immediately with a grave
accent is an error.

In order to ensure that it is harmless to use the Dog metatemplate
preprocessor on all Dog templates, Dog templates that do not require
metatemplate preprocessing simply must ensure that none of their lines
begin immediately with a grave accent.

This preprocessor is required to properly localize the datetime format
used in certain Dog templates.  The datetime format is specified by the
provided JSON file.

The JSON file must be a JSON array of zero or more elements.  Each
element in the array is either a string or a subarray that contains
exactly one string element.  String elements are literal text that is
always included in fixed form in the datetime string.  Subarray elements
contain the name of a datetime element that should be inserted based on
the datetime that is being rendered.  The following elements are
available:

=over 4

=item C<year>

The four-digit Gregorian year.

=item C<month_variable>

The month as a decimal number in range [1, 12], which might have either
one or two digits.

=item C<month_fixed>

The same as C<month_variable>, except one-digit months are zero-padded
up to two digits so that each month is exactly two digits.

=item C<month_long>

The localized long name of the month, as determined by the Yip CMS.

=item C<month_short>

The localized short name of the month, as determined by the Yip CMS.

=item C<day_variable>

The day as a decimal number in range [1, 31], which might have either
one or two digits.

=item C<day_fixed>

The same as C<day_variable>, except one-digit days are zero-padded up to
two digits so that each day is exactly two digits.

=item C<hour24_variable>

The hour (24-hour system) as a decimal number in range [0, 23], which
might have either one or two digits.

=item C<hour24_fixed>

The same as C<hour24_variable>, except one-digit hours are zero-padded
up to two digits so that each hour is exactly two digits.

=item C<hour12_variable>

The hour (12-hour system) as a decimal number in range [1, 12], which
might have either one or two digits.

=item C<hour12_fixed>

The same as C<hour12_variable>, except one-digit hours are zero-padded
up to two digits so that each hour is exactly two digits.

=item C<apm_lower>

Either the lowercase letter C<a> or the lowercase letter C<p> depending
on whether the time is AM or PM in the 12-hour system.  Note that this
does I<not> include the C<m> that should follow this letter!

=item C<apm_upper>

The same as C<apm_lower> except the letter is uppercase.

=item C<minute>

The minute as a two-digit decimal number in range [00, 59], with zero
padding used to ensure every value is exactly two digits.

=item C<second>

The second as a two-digit decimal number in range [00, 59], with zero
padding used to ensure every value is exactly two digits.

=back

For example, to get a datetime in this format:

  May 20, 2022 at 7:23PM

You could use the following JSON datetime definition:

  [
    ["month_long"],
    " ",
    ["day_variable"],
    ", ",
    ["year"],
    " at ",
    ["hour12_variable"],
    ":",
    ["minute"],
    ["apm_upper"],
    "M"
  ]

=cut

# =========
# Constants
# =========

# A mapping from Dog metatemplate variable names to the Yip template
# code they should be replaced by in the compiled template.
#
my %TCODE = (
  'year'            => '<TMPL_VAR NAME=_year>',
  'month_variable'  => '<TMPL_VAR NAME=_mon>',
  'month_fixed'     => '<TMPL_VAR NAME=_monz>',
  'month_long'      => '<TMPL_VAR NAME=_monl ESCAPE=HTML>',
  'month_short'     => '<TMPL_VAR NAME=_mons ESCAPE=HTML>',
  'day_variable'    => '<TMPL_VAR NAME=_day>',
  'day_fixed'       => '<TMPL_VAR NAME=_dayz>',
  'hour24_variable' => '<TMPL_VAR NAME=_hr24>',
  'hour24_fixed'    => '<TMPL_VAR NAME=_hr24z>',
  'hour12_variable' => '<TMPL_VAR NAME=_hr12>',
  'hour12_fixed'    => '<TMPL_VAR NAME=_hr12z>',
  'apm_lower'       => '<TMPL_VAR NAME=_apml>',
  'apm_upper'       => '<TMPL_VAR NAME=_apmu>',
  'minute'          => '<TMPL_VAR NAME=_minz>',
  'second'          => '<TMPL_VAR NAME=_secz>'
);

# ==================
# Program entrypoint
# ==================

# If no parameters given, show brief help screen and quit
#
if ($#ARGV < 0) {
  print { \*STDERR } q{Syntax:

  dogmeta.pl -date [datefile] < template.meta > template.tmpl

[datefile] is a JSON file containing the datetime format.
};
  exit;
}

# Switch input and output to raw binary
#
binmode(STDIN , ":raw") or die "Failed to set binary input, stopped";
binmode(STDOUT, ":raw") or die "Failed to set binary output, stopped";

# Check invocation syntax
#
($#ARGV == 1) or die "Wrong number of program arguments, stopped";
($ARGV[0] eq '-date') or die "Invalid program arguments, stopped";

# Get and check argument
#
my $json_path = $ARGV[1];
(-f $json_path) or die "Can't find file '$json_path', stopped";

# Read the whole JSON file in as a binary string
#
open(my $jh, "< :raw", $json_path) or
  die "Failed to open file '$json_path', stopped";
my $json;
{
  local $/;
  $json = readline($jh);
}
close($jh);

# Parse the JSON
#
eval {
  $json = decode_json $json;
};
if ($@) {
  die "Failed to parse JSON datetime format: $@";
}

# Check that the JSON is an array
#
(ref($json) eq 'ARRAY') or
  die "JSON datetime format must be array, stopped";

# Go through the JSON array, check that each element is either a scalar
# or a subarray containing a single scalar, and replace all elements
# with strings, with subarrays mapped to the appropriate Yip template
# code
#
for(my $i = 0; $i < scalar(@$json); $i++) {
  # Different handling depending on type
  if (not ref($json->[$i])) { # ========================================
    # Scalar element, so get the string value
    my $str = $json->[$i];
    
    # Make sure string only contains valid codepoints
    ($str =~ /\A[\x{1}-\x{d7ff}\x{e000}-\x{10ffff}]*\z/) or
      die "JSON string literal contains invalid codepoints, stopped";
    
    # Make sure element is stored as a string
    $json->[$i] = "$str";
    
  } elsif (ref($json->[$i]) eq 'ARRAY') { # ============================
    # Array element, so make sure it has exactly one element that is a
    # scalar
    (scalar(@{$json->[$i]}) == 1) or
      die "JSON subarrays must have exactly one element, stopped";
    (not ref($json->[$i]->[0])) or
      die "JSON subarrays must have scalar element, stopped";
    
    # Replace this element with the appropriate Yip template code
    my $str = $json->[$i]->[0];
    (defined $TCODE{$str}) or
      die "Unrecognized datetime variable '$str', stopped";
    $json->[$i] = $TCODE{$str};
    
  } else { # ===========================================================
    die "JSON datetime array contains invalid element type, stopped";
  }
}

# Now form our compiled datetime template code
#
my $datetime_code = join '', @$json;

# Read the whole metatemplate into a raw binary string
#
my $tc;
{
  local $/;
  $tc = <STDIN>;
}

# If the metatemplate begins with UTF-8 BOM, drop it
#
$tc =~ s/\A\x{ef}\x{bb}\x{bf}//;

# Split the metatemplate into lines on newline characters (works with
# both LF and CR+LF)
#
my @lines = split /\n/, $tc;

# Process line by line
#
for my $lstr (@lines) {
  # Check type of line and handle the different kinds
  if (not ($lstr =~ /\A`/)) { # ========================================
    # Doesn't begin with grave accent, so output as-is
    print "$lstr\n";
    
  } elsif ($lstr =~ /\A`D[ \t\r]*/) { # ================================
    # Metatemplate command to insert datetime code, so add the code
    print $datetime_code;
    
    # If the line ends with a carriage return, output carriage return
    # followed by line break, else just line break
    if ($lstr =~ /\r\z/) {
      print "\r\n";
    } else {
      print "\n";
    }
    
  } else { # ===========================================================
    # Only other valid case is a metatemplate comment
    (($lstr =~ /\A`\z/) or ($lstr =~ /\A`[ \t\r]/)) or
      die "Unrecognized template metacommand: '$lstr'";
    
    # Don't output anything in this case
  }
}

=head1 AUTHOR

Noah Johnson, C<noah.johnson@loupmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 Multimedia Data Technology Inc.

MIT License:

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
