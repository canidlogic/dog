# Access control

This document describes the _access control_ models available for handling web clients.  Access control only applies to clients that are accessing catalog pages, content pages, or resources through an HTTP(S) interface.  It does not apply to administrative functions performed in the shell, which are assumed to have already been authenticated by some other means, such as SSH.

Dog CMS supports three models of access control for web clients:

1. __Public:__ no restriction on access
2. __Guest:__ must agree to something first
3. __Private:__ username and password required

The _public_ model is the default access control model.  To select other access control models, the variable `access_control` must be defined in the `vars` table of the Dog CMS database, with the value being either `public` or `guest` or `private` (case sensitive).

The more restrictive the access control, the more is required to secure access.  The following table shows what is required for each access control model:

      Model  | Cookies? | HTTPS? | Write?
    ---------+----------+--------+--------
     public  |   no     |   no   |   no
     guest   |   YES    |   no   |   no
     private |   YES    |   YES* |   YES

The `cookies` requirement means that the web client must support HTTP(S) cookies and allow them for the website.  The `HTTP(S)` requirement means that the site must be deployed on HTTPS (but see below).  The `write` requirement means that write access to the Dog CMS database is required (for the sole purpose of tracking failed login attempts and throttling password guesses).

(It is possible to force Dog CMS to use `private` access model on unsecured HTTP but this is __not secure__ because user passwords will be transmitted to the server without encryption!!  To allow `private` access control on unsecured HTTP, you must define in the `vars` table a variable named `leak_passwords` and set it to the value 1.)

## Cookie format

All modes except `public` use a cookie to control access.  The value of a cookie always has the following format:

    p|name|f3770d22c98a4ba4570ede23fcbd6d42

The start of the cookie value is always either `p|` for a persistent cookie or `s|` for a session cookie.  Persistent cookies choose the default behavior.  `s|` selects a behavior that the cookie should never be given an expiration time, even if `cookie_expires` is configured (see below).  This allows users to login only for one session on the device.

The `name` is a username.  This is always followed by a vertical bar `|` and then an HMAC-MD5.  In the `user` table in the Dog CMS database, each user has a secret, randomly-generated key that is used with the HMAC-MD5.  For the cookie value to be validated, it must have the format shown above AND the HMAC-MD5 must match the provided username, using the secret key from the user record in the `user` table.

In `guest` mode, the username is always `guest` while in `private` mode, the username is never `guest`.  Private-mode usernames must consist of at least one Unicode codepoint, all Unicode codepoints must be in Unicode range, excluding [0x00, 0x20] and 0x7f in ASCII range as well as surrogates, and the username may not be `guest` (case sensitive) after normalization.  Unicode normalization to NFC form is always performed on usernames, and the normalized username is what is run through the HMAC-MD5.

Changing the secret key of a particular user to a different random value will immediately invalidate any currently active cookies.  In `guest` mode, resetting the secret key of the `guest` user record has the effect of requiring everyone to go through the agreement process again (useful if the agreement has changed).  In `private` mode, resetting the secret key of a particular user has the effect of logging them out of all sessions and requiring a new log-in and authentication.

The rest of the cookie parameters are controlled by variables in the `vars` table, which all have default values if the variables are not present:

- `cookie_name` (default: `cmscookie`) - the name of the cookie
- `cookie_path` (default: `/`) - the path of the cookie
- `cookie_domain` (default: `.`) - the domain of the cookie
- `cookie_expires` (default: `0`) - the expiration of the cookie
- `cookie_secure` (default: `0`) - force cookie on HTTPS only

For all of these variables except `cookie_name`, if the variable has its default value as shown above, then the corresponding parameter will _not_ be included in the cookie definition.  For the path, this means the cookie will be available everywhere.  For the domain, this means the cookie is limited to the host of the current document.  For the expiration, this means the cookie is good only for the current session.  For the secure flag, this means the cookie can also be used on unsecured HTTP.

The `cookie_name` is the name of the cookie.  It may only contain US-ASCII alphanumeric characters, and it must have at least one and at most 32 such characters.

The `cookie_path`, if present, should be an absolute path starting with `/` that selects a specific directory in the public HTML path, _not_ including a `/` after the directory name.  The cookie will only be visible within the specified directory and all subdirectories.

The `cookie_domain`, if present, should be a domain name that is prefixed with a `.` dot, and at least two dots including these opening dot should be present.  The cookie will be visible only in the selected domain _and all subdomains._  For example, if the cookie domain is `.public.example.com` then the cookie will be visible in `public.example.com` and `www2.public.example.com` but not in `example.com`.

The `cookie_expires`, if present, is the duration that the cookie can be stored by the client.  This must have the format of a sequence of one or more decimal digits followed by a unit designation letter.  The units `s` (second) `m` (minute) `h` (hour) and `d` (day) are supported.  Each time a validated cookie is accepted when an expiration time is configured, the cookie will be reset on the client with an updated expiration time so that the client may keep on using the cookie.  However, if the cookie value starts with `s|` (see earlier), then this variable value is ignored and the cookie always lasts for only the current session.

The `cookie_secure` flag, if present AND equal to `1`, indicates that the client should only send this cookie over a secure HTTPS connection.  Don't use this unless you are running the Dog CMS site exclusively on HTTPS!

## Gateway script

The _gateway script_ validates a user, gives the user an appropriate access cookie, and redirects the user to the protected resource they had initially requested.

The gateway script is POSTed variables.  In `guest` mode, the following variables are required in the POST request:

- `time` - the timestamp of the request
- `check` - the HMAC-MD5 of the timestamp

The `time` is the number of seconds since midnight GMT at the start of January 1, 1970.  In order for the request to validate, this point in time must not be too far in the past.  By default, this means that the given `time` must be less than one hour in the past.  If `guest_agree_time` is defined in the `vars` table, then the value of this variable is the number of seconds, which replaces the one-hour default.

If the `time` is not too far in the past, the next check is that the `check` variable is a valid HMAC-MD5 of the ASCII decimal representation of `time`.  The secret key for this HMAC-MD5 is stored in the `guest_agree_key` variable in the `vars` table.

The `guest` mode request validates if both these POSTed values are confirmed as described above.  Otherwise, the `guest` mode request is invalid.

In `private` mode, the following variables are required in the POST request:

- `uname` - the username
- `password` - the password for the user

The `uname` must not be `guest` or the request is automatically invalid.  Otherwise, the request is validated only if `uname` is in the `user` table AND `password` matches the password hash for that user.

In both `guest` and `private` mode, the request may include the following variable to control cookie persistence:

- `persist_mode` - set to `remember` (default) or `forget`
- `persist_flip` - set to `flip` to flip the mode

The `persist_mode` chooses the regular behavior of whether cookie values should have the `p|` or `s|` prefix (see earlier).  The `persist_flip` is set to `flip` to flip the persist mode to the other value.  For example, if a login page normally should have `forget` mode but the user has a "remember me" checkbox, then `persist_mode` should be `forget` and the "remember me" checkbox should set `persist_flip` to `flip`.

In both `guest` and `private` mode, the request may include the following variables to indicate where the user should be redirected to after successful validation:

- `rtype` - either `catalog` or `page`
- `rcode` - either catalog page number or page ID code

If either or both of these variables is missing, or the redirection location is not recognized, then the gateway script will assume redirection to the first catalog page.

Upon successful validation, the gateway script will set an appropriate access cookie as described in the previous section and then redirect to the requested redirect location, as determined above.

If the request is not validated, the gateway script checks for a redirect variable in the `vars` table.  The redirect variables are:

- `guest_invalid_catalog` - guest mode, redirect to catalog
- `guest_invalid_page` - guest mode, redirect to page
- `login_invalid_catalog` - private mode, redirect to catalog
- `login_invalid_page` - private mode, redirect to page

The redirect URL is formed by selecting the appropriate redirect variable and then suffixing either the catalog page number or the content page ID.  The gateway script then redirects to the redirect URL.  If the appropriate redirect variable is not defined, 403 "Forbidden" will be generated by the script.

## Gateway throttling

By default, the gateway script allows an unlimited number of attempts at logging in for each user.  You can secure this system further by throttling login attempts to prevent brute-force guessing.  Throttling only applies to `private` access mode.

To enable throttling, you must define the following variable in the `vars` table:

- `throttle_pattern` - program string for throttling

The `throttle_pattern` is a string in a special format that dictates how throttling is performed.  The string is a sequence of unsigned decimal integers.  These integers are organized into pairs that are separated internally by a comma, and pairs are separated from each other by semicolons.  For example:

    15,60;3,7200;5,432000;6,0

The throttle pattern is decoded into a sequence of moduli and delays.  The second number in each pair is a delay value.  The first number in the first pair is the first moduli.  The first number in the second pair is the second moduli divided by the first moduli.  The first number in pair _n_ is the _n_-th moduli divided by the (_n_ - 1)-th moduli.  The above example would then decode to:

     Modulus | Delay
    ---------+--------
          15 |     60
          45 |   7200
         225 | 432000
        1350 |      0

The first integer in each pair must always be greater than zero.  The second integer in each pair must be greater than or equal to zero.

Delay values that are greater than zero express a duration in seconds.  The delay value of zero has the special interpretation that means permanent delay.

Each user record in the `user` table of the Dog CMS database (except the special `guest` record) stores the number of failed login attempts, which is greater than or equal to zero.  It also stores the time of the last failed login attempt, or zero if the number of failed login attempts is zero.  When a login attempt is made, let _n_ be the failed login attempt number for that user prior to this login.  If _n_ is zero, then the login attempt is never throttled.  If _n_ is greater than zero, then go through the moduli table in reverse order from greatest modulus to least modulus.  Find the record with the greatest moduli for which _n_ modulo this modulus is zero.  If there is no such record, the login attempt is not throttled.  If there is such a record, the login attempt is always throttled if the delay value is zero; otherwise, it is throttled if less than _delay_ seconds has passed since the last failed login attempt.

The example moduli table given above means that the user is permitted 14 failed login attempts in a row, but on each 15th failed login attempt, there is a one-minute delay; on each 45th failed login attempt, there is a two-hour delay; on each 225th failed login attempt, there is a a five-day delay, and after 1350 failed login attempts, further attempts to login are always throttled.

When a login attempt is throttled, the gateway script does not even check whether the username and password combination is valid.  Instead, the user is redirected using the following variables:

- `throttle_catalog` - throttle, redirect to catalog
- `throttle_page` - throttle, redirect to page

The redirection URL is formed by taking the appropriate variable and suffixing either the catalog page number or the content page ID.  If the appropriate variable is not present, 403 "Forbidden" is returned.

Each user record has fields that store the maximum failed login count that was reached and the time at which that failed attempt was reached.  These statistics fields are only reset when manually done so by an administrator.  This allows administrators to watch for suspicious behavior.  Administrators may also restore login access to a user whose login is currently being throttled by resetting their failed login attempt count to zero.

## Cache behavior

The cache behavior is affected by access control, as well as whether a page or a resource is being requested.  "Page" here refers to both content pages and catalog pages.  The following table shows the `Cache-Control` settings for pages and resources in each of the access modes:

            |       Page        |         Resource
    --------+-------------------+---------------------------
    public  | no-cache          | max-age=31536000
    guest   | private, no-cache | private, max-age=31536000
    private | no-store          | no-store

For `private` mode, `no-store` is specified for both pages and resources, which requests that there should be no caching of any kind.  This is to prevent information leaking through cached data, at the expense of access speed.

For `guest` mode, the settings are the same as `public`, except the `private` keyword is added.  This indicates that results may be cached on local web clients, but not in shared caches or in proxies.  This forces each client to go through the agreement process before they can access data, but then allows clients to cache once the agreement has been accepted.

For content and catalog pages, page content may change over time while still being at the same URL.  The `no-cache` setting is used in `public` mode, which means (confusingly) that pages _may_ be cached, but caches should always check with the server to see if the cached page is still valid or if a newer version should be fetched.  Dog CMS uses ETags to keep track of page versions.  The ETag of a catalog page or a content page is the SHA-1 digest of the fully generated page.  This means that even if the page is re-generated, it will keep the same ETag and therefore remain in the cache if the re-generated result is exactly the same as the previous version.

For resources, Dog CMS assigns each version of a resource a unique code and therefore a unique URL.  Since each version of a resource has its own URL, resource URLs can be assumed to be immutable.  This is selected in the cache control by specifying that results may be cached for up to a full year.

## Public access control

In the default `public` model of access control, web clients may freely access any catalog page, resource, and content page in the Dog CMS database without any kind of cookie or authentication.  The `user` table in the Dog CMS database is completely ignored.

## Guest access control

In the `guest` model of access control, anyone may access catalog pages, resources, and content pages, but first they have to click through some kind of agreement screen.  To enforce this, for any access to a catalog page, resource, or content page, a check will be made that the client provided an appropriate access cookie for user `guest` (see earlier).  If so, then the requested data is returned successfully.

If an appropriate access cookie is not provided, then the following two variables in the `vars` table are relevant:

- `guest_agree_catalog` : URL prefix for catalog page agreement
- `guest_agree_content` : URL prefix for content page agreement

If a catalog page was requested but no valid cookie was provided, the user is redirected to an URL formed by taking `guest_agree_catalog` and appending the catalog page number to it.  If a content page was requested but no valid cookie was provided, the user is redirected to an URL formed by taking `guest_agree_content` and appending the page ID to it.  If the appropriate variable is not defined, then 403 "Forbidden" is returned.

Resource requests always fail with 403 "Forbidden" because there is no idiomatic way of redirecting a resource request to a webpage.

The redirection target of `guest_agree_catalog` and `guest_agree_content` should be the agreement page, which is not defined within the Dog CMS system.  It is recommended that this page be implemented with hidden HTML form controls that have the current time and the HMAC-MD5 of the current time using a copy of the secret key from the `guest_agree_key` variable.  This copy of the secret key must be stored server-side and not transmitted to the client, however!  The hidden HTML form controls should also include the redirection target, and then the "Agree" button is a form submit to the gateway script described earlier, while the "Disagree" button takes the user outside of the site somewhere.  Remember to add `no-store` cache control to this agreement page so that a fresh copy with a fresh time is generated each request.

## Private access control

In the `private` model of access control, all access to catalog pages, resources, and content pages is protected by username and password authentication.  A check will be made that the client provided an appropriate access cookie for any user _except_ `guest` (see earlier).  If so, then the requested data is returned successfully.

If an appropriate access cookie is not provided, then the following two variables in the `vars` table are relevant:

- `login_for_catalog` : URL prefix for catalog page login
- `login_for_content` : URL prefix for content page login

If a catalog page was requested but no valid cookie was provided, the user is redirected to an URL formed by taking `login_for_catalog` and appending the catalog page number to it.  If a content page was requested but no valid cookie was provided, the user is redirected to an URL formed by taking `login_for_content` and appending the page ID to it.  If the appropriate variable is not defined, then 403 "Forbidden" is returned.

Resource requests always fail with 403 "Forbidden" because there is no idiomatic way of redirecting a resource request to a webpage.

The redirection target of `login_for_catalog` and `login_for_content` should be the login page, which is not defined within the Dog CMS system.  It is recommended that this page be implemented with hidden HTML form controls that include the redirection target.  There are form controls for entering the username and password.  The form is then submitted to the gateway script.  It should also be possible to use the form page as the invalidated redirection target, by providing a variable that displays an error message and to try again.
