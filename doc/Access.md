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

The following sections describe the operation of the different models of access control.

## Public access control

In the default `public` model of access control, web clients may freely access any catalog page, resource, and content page in the Dog CMS database without any kind of cookie or authentication.  The `user` table in the Dog CMS database is completely ignored.

The `public` model has the fastest behavior with caches.  Since everything is public, everything can be cached anywhere.  Resources are designed to have a unique URL for each version, so each resource will be served with a `max-age` of one year to allow resource versions to be cached anywhere for a long time.  Catalog pages and content pages will be served with `no-cache` which does __not__ mean that they shouldn't be cached.  Instead, this is interpreted to mean that pages may be cached anywhere for any length, but they should always be validated with the server to make sure they are fresh.  ETags with a SHA-1 digest of the page contents are used to check whether pages are identical copies.

## Guest access control

In the `guest` model of access control, anyone may access catalog pages, resources, and content pages, but first they have to click through some kind of agreement screen.  `access_control` must be defined in the `vars` table with the value `guest` and there must be a record in the `user` table for a user named `guest`.  All other user records are ignored in this access control mode.

When an attempt is made to access a catalog page, a resource, or a content page, first a check will be made for a cookie with the default name `guest`, or otherwise the name defined in `guest_cookie_name` in the `vars` table -- which must have a value that only has alphanumeric ASCII characters with a minimum length of one and a maximum length of 32.  If the cookie does not exist, resource requests will fail with an HTTP status code of of 403 "Forbidden" while catalog page and content page requests will redirect the user to the agreement page or fail with 403 "Forbidden" if the agreement page is not set up properly.

To set up the agreement page properly, define the following variables in the `vars` table:

- `guest_agree_catalog` : URL prefix for catalog page agreement
- `guest_agree_content` : URL prefix for content page agreement

When a request for a catalog page does not have the proper cookie, the user is redirected to the URL formed by `guest_agree_catalog` with the catalog page number suffixed to it.  When a request for a content page does not have the proper cookie, the user is redirected to the URL formed by `guest_agree_content` with the content page ID suffixed to it.  This agreement page is not defined by the Dog CMS.  It is expected to either have a "disagree" option that takes the user outside the site, or an "agree" button that submits a POST request to the Dog CMS guest script.

The Dog CMS guest script takes four POSTed variables:  the current time as the number of seconds that have elapsed since midnight GMT at the start of January 1, 1970, an HMAC-MD5 of the current time, a flag indicating whether to redirect to a catalog page or content page, and the number of the catalog page or ID of the content page.  For the guest script submission to be valid, the current time submitted must be not too far in the past AND the HMAC-MD5 must be valid.  "Too far in the past" is by default 15 minutes or more, but this can be changed by defining `guest_agree_time` in the `vars` table with the number of seconds allowed.  The secret key for the HMAC-MD5 must be defined in the variable `guest_agree_key` in the `vars` table in the Dog CMS database.  The agreement page should also have a copy of the secret key in the server-side script or somewhere on the server.  (Do __not__ transmit the secret key to the web client!)  The agreement page server-side script can then generate hidden HTML form fields that contain the time the agreement page was generated, the HMAC-MD5 for that time, and the redirect location, and the "Agree" button can then do a form submission to the Dog CMS guest script.  Remember to use `no-store` cache control on the agreement page so that a fresh agreement page with a fresh time is retrieved each time.

If the time and HMAC received by the Dog CMS guest script are valid, then the script will give a guest cookie to the web client and redirect the client to the requested catalog or content page, or to the first page of the catalog if the redirect location was not understood.  Otherwise, the script will fail with a 403 "Forbidden" error.

The name of the guest cookie is either the default `guest` or the name defined in `guest_cookie_name` in the `vars` table, as described earlier.  The value of the guest cookie is the prefix `guest|` and then an HMAC-MD5 of the word `guest` using the session key defined for the `guest` user in the `user` table.  Changing the session key for `guest` in the `user` table will force everyone to go through the agreement screen again to get a new cookie -- useful when changing the agreement page.

The path, domain, and expires fields of the cookies generated by the Dog CMS guest script may be set with the following variables in the `vars` table:

- `guest_cookie_path`
- `guest_cookie_domain`
- `guest_cookie_expires`

If path is not specified, it is not specified in the cookie, which has a default meaning of site-wide.  If domain is not specified, it is not specified in the cookie, which has a default meaning of only the current domain.  If expires is not specified, it is not specified in the cookie, which has a deafult meaning of cookie only lasts for this session.  See the documentation of the Perl `CGI` module for further information about the path, domain, and expires settings.  The expires setting follows the Perl `CGI` syntax rather than the HTTP syntax!

When checking the guest cookie, if the check does not validate the cookie contents, the situation is handled the same way as if the user did not have the cookie defined.

Caching behavior in `guest` mode is the same as in `public` mode, except that `private` is included, so that data may only be cached on web clients and not on shared caches.
