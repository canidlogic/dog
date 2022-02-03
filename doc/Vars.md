# Configuration variables

This document is a compilation of all the configuration variables from the `vars` table that are mentioned in other documentation files.

## Catalog page configuration

These variables control the canonical URL of each catalog page, how listed items are grouped and sorted onto catalog pages, and the appearance of the jump link list.

- `catalog_prefix` : string prefix to catalog page number for URL
- `catalog_first` : special URL for the first catalog page
- `chronology` : `reverse` (default) or `forward`
- `catalog_capacity` : integer, `20` is default
- `jump_window_before` : integer, `2` is default
- `jump_window_after` : integer, `2` is default
- `jump_bumper_start` : integer, `2` is default
- `jump_bumper_end` : integer, `2` is default

## Content page configuration

These variables control the canoncial URL of each content page, and how page IDs are rendered for display.

- `page_prefix` : string prefixed to all page URL fields
- `page_name_ucase` : `0` (default) or `1`
- `page_name_special` : replacement string for underscore

## Resource configuration

These variables control the canonical URL of each resource.

- `resource_prefix` : string prefixed to resource code for URL

## Embed configuration

These variables control how embedded text is generated.

- `recurse_limit` : integer, `32` is default

## Date and time configuration

These variables control how time and dates are rendered for display.

- `time_zone` : `UTC` (default) or time zone code
- `time_locale` : locale for time/date formatting
- `time_format` : `%Y-%m-%d` (default) or time/date format

## Access control variables

This section and the following subsections affect access control.  If none of these variables are defined, then the default `public` access model is used.

- `access_control` : `public` (default) `guest` or `private`
- `leak_passwords` : `0` (default) or `1`

### Access cookie parameters

These variables control the parameters used for access cookies returned to the client in `guest` and `private` access mode.

- `cookie_name` : default is `cmscookie`
- `cookie_path` : default is `/`
- `cookie_domain` : default is `.`
- `cookie_expires` : `0` (default) or time duration format
- `cookie_secure` : `0` (default) or `1`

### Guest access mode variables

These variables are specific to `guest` access mode.

- `guest_agree_time` : integer value, `3600` is default
- `guest_agree_key` : HMAC agreement key for guest access mode
- `guest_agree_catalog` : catalog redirect prefix for guest agreement
- `guest_agree_content` : page redirect prefix for guest agreement
- `guest_invalid_catalog` : catalog redirect prefix for failed guest agreement
- `guest_invalid_page` : page redirect prefix for failed guest agreement

### Private access mode variables

These variables are specific to `private` access mode.

- `login_for_catalog` : catalog redirect prefix for private login
- `login_for_content` : page redirect prefix for private login
- `login_invalid_catalog` : catalog redirect prefix for failed private login
- `login_invalid_page` : page redirect prefix for failed private login

### Login throttling variables

These variables are used to set up login throttling on `private` access mode for greater security.

- `throttle_pattern` : program string for private login throttling
- `throttle_catalog` : catalog redirect prefix for throttled login
- `throttle_page` : page redirect prefix for throttled login
