# NAME

dogmeta.pl - Compile Dog metatemplates into Yip templates.

# SYNOPSIS

    ./dogmeta.pl -date datestr.json < template.meta > template.tmpl

# DESCRIPTION

Given a Dog metatemplate and a JSON file defining the datetime format,
compile a Yip template using that given datetime format.

This preprocessor only is required for Dog templates that end with the
extension `.meta` though no harm will result if it is run on Dog
templates that end with the extension `.tmpl` (in that case, the
template will just be output as-is).

Dog metatemplate files are processed line by line.  Lines that do not
begin immediately with a grave accent character are sent to output
as-is.  Lines that begin immediately with a grave accent character are
metatemplate lines.  If the line is blank apart from the grave accent or
there is a space or tab immediatley after the grave accent, the
metatemplate line is a comment that is discarded and not included in
output.  If the line contains grave accent, an uppercase `D` and then
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

- `year`

    The four-digit Gregorian year.

- `month_variable`

    The month as a decimal number in range \[1, 12\], which might have either
    one or two digits.

- `month_fixed`

    The same as `month_variable`, except one-digit months are zero-padded
    up to two digits so that each month is exactly two digits.

- `month_long`

    The localized long name of the month, as determined by the Yip CMS.

- `month_short`

    The localized short name of the month, as determined by the Yip CMS.

- `day_variable`

    The day as a decimal number in range \[1, 31\], which might have either
    one or two digits.

- `day_fixed`

    The same as `day_variable`, except one-digit days are zero-padded up to
    two digits so that each day is exactly two digits.

- `hour24_variable`

    The hour (24-hour system) as a decimal number in range \[0, 23\], which
    might have either one or two digits.

- `hour24_fixed`

    The same as `hour24_variable`, except one-digit hours are zero-padded
    up to two digits so that each hour is exactly two digits.

- `hour12_variable`

    The hour (12-hour system) as a decimal number in range \[1, 12\], which
    might have either one or two digits.

- `hour12_fixed`

    The same as `hour12_variable`, except one-digit hours are zero-padded
    up to two digits so that each hour is exactly two digits.

- `apm_lower`

    Either the lowercase letter `a` or the lowercase letter `p` depending
    on whether the time is AM or PM in the 12-hour system.  Note that this
    does _not_ include the `m` that should follow this letter!

- `apm_upper`

    The same as `apm_lower` except the letter is uppercase.

- `minute`

    The minute as a two-digit decimal number in range \[00, 59\], with zero
    padding used to ensure every value is exactly two digits.

- `second`

    The second as a two-digit decimal number in range \[00, 59\], with zero
    padding used to ensure every value is exactly two digits.

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

# AUTHOR

Noah Johnson, `noah.johnson@loupmail.com`

# COPYRIGHT AND LICENSE

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
