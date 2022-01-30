#!/usr/bin/env perl
use strict;
use feature 'unicode_strings';
use warnings FATAL => "utf8";

# Non-core includes
use DBI;
use DBD::SQLite::Constants ':dbd_sqlite_string_mode';

=head1 NAME

dogmake.pl - Create a new, empty Dog CMS database.

=head1 SYNOPSIS

  dogmake.pl newdb.sqlite

=head1 DESCRIPTION

Given the path to a SQLite database to create, open the database and
perform an exclusive transaction that creates all the tables necessary
for a Dog CMS database.

If the given file path does not exist, a brand-new SQLite database will
be created there.

An empty Dog CMS database is a valid Dog CMS database, so you can start
using the newly created database immediately after this script.

See C<Database.md> in the C<doc> directory for a description of the
database structure.

=cut

# ==========
# SQL script
# ==========

# This string stores the SQL statements necessary for creating all the
# tables with the appropriate structure, EXCLUDING the begin transaction
# and commit statements.
#
# SQL statements in this string each end with a semicolon.
#
# CAUTION: use the semicolon character in this string ONLY for ending
# SQL statements, or the SQL script may be parsed incorrectly!
#
# The SQL statements here are copied from Database.md in the doc
# directory.
#
my $sql_script = q{

    CREATE TABLE vars(
      vid  INTEGER PRIMARY KEY,
      vkey TEXT UNIQUE NOT NULL,
      vval TEXT
    );

    CREATE UNIQUE INDEX vars_ikey ON vars(vkey);

    CREATE TABLE page(
      pid    INTEGER PRIMARY KEY,
      pname  TEXT UNIQUE NOT NULL,
      ptime  INTEGER UNIQUE NOT NULL,
      pclass INTEGER NOT NULL,
      pjson  TEXT NOT NULL,
      plist  TEXT NOT NULL,
      ppage  TEXT NOT NULL,
      purl   TEXT NOT NULL
    );

    CREATE UNIQUE INDEX page_iname ON page(pname);
    CREATE UNIQUE INDEX page_itime ON page(ptime);
    CREATE INDEX page_iclass ON page(pclass);
    CREATE UNIQUE INDEX page_rchrono ON page(pclass DESC, ptime DESC);
    CREATE UNIQUE INDEX page_fchrono ON page(pclass DESC, ptime ASC);

    CREATE TABLE mime(
      mid   INTEGER PRIMARY KEY,
      mkey  TEXT UNIQUE NOT NULL,
      mtype TEXT NOT NULL
    );

    CREATE UNIQUE INDEX mime_ikey ON mime(mkey);

    CREATE TABLE resource(
      rid   INTEGER PRIMARY KEY,
      rpage INTEGER
              REFERENCES page(pid)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
      rname TEXT NOT NULL,
      rtime INTEGER NOT NULL,
      rcode TEXT UNIQUE NOT NULL,
      rtype INTEGER NOT NULL
              REFERENCES mime(mid)
                ON DELETE RESTRICT
                ON UPDATE CASCADE,
      rdata BLOB NOT NULL,
      UNIQUE(rpage, rname, rtime)
    );

    CREATE UNIQUE INDEX resource_imulti
      ON resource(rpage, rname, rtime DESC);
    CREATE INDEX resource_iname
      ON resource(rpage, rname);
    CREATE INDEX resource_ipage
      ON resource(rpage);

    CREATE UNIQUE INDEX resource_icode
      ON resource(rcode);
    CREATE INDEX resource_itype
      ON resource(rtype);
    
    CREATE TABLE embed(
      eid   INTEGER PRIMARY KEY,
      epage INTEGER
              REFERENCES page(pid)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
      ename TEXT NOT NULL,
      eproc INTEGER NOT NULL,
      etext TEXT NOT NULL,
      UNIQUE(epage, ename)
    );

    CREATE UNIQUE INDEX embed_imulti ON embed(epage, ename);
    CREATE INDEX embed_ipage ON embed(epage);

    CREATE TABLE catalog(
      cid   INTEGER PRIMARY KEY,
      cnum  INTEGER UNIQUE NOT NULL,
      cetag TEXT,
      ctext TEXT
    );

    CREATE UNIQUE INDEX catalog_inum ON catalog(cnum);

    CREATE TABLE content(
      tid   INTEGER PRIMARY KEY,
      tname TEXT UNIQUE NOT NULL,
      tetag TEXT,
      ttext TEXT
    );

    CREATE UNIQUE INDEX content_iname ON content(tname);

    CREATE TABLE user(
      uid     INTEGER PRIMARY KEY,
      uname   TEXT UNIQUE NOT NULL,
      upswd   TEXT NOT NULL,
      ukey    TEXT NOT NULL,
      ufcount INTEGER NOT NULL,
      uftime  INTEGER NOT NULL,
      uxcount INTEGER NOT NULL,
      uxtime  INTEGER NOT NULL
    );

    CREATE UNIQUE INDEX user_iname ON user(uname);

};

# ==================
# Program entrypoint
# ==================

# Check that exactly one parameter
#
($#ARGV == 0) or die "Expecting one parameter, stopped";

# Get the database path parameter
#
my $db_path = $ARGV[0];

# Connect to the database, creating it if the file is not defined
#
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", undef, undef, {
  AutoCommit => 0,
  RaiseError => 1
}) or die "Failed to connect to or create database, stopped";

# Set Unicode support
#
$dbh->{sqlite_string_mode} = DBD_SQLITE_STRING_MODE_UNICODE_STRICT;

# Begin an exclusive transaction to define the structure
#
$dbh->do(q{BEGIN EXCLUSIVE TRANSACTION});

# Wrap the rest in an eval so that any error causes a rollback
#
eval {
  
  # Split the SQL script into individual statements around semicolons
  my @cmds = split /;/, $sql_script;
  
  # Must be at least two elements in the command list, since the last
  # element is just the space after the last semicolon
  ($#cmds >= 1) or
    die "Invalid SQL script, stopped";
  
  # Last element must just contain whitespace and line breaks, and then
  # remove it after checking
  ((pop @cmds) =~ /^[ \t\r\n]*$/) or
    die "Invalid SQL script, stopped";
  
  # Now run all the SQL statements in order
  for my $sql (@cmds) {
    $dbh->do($sql);
  }
  
  # Commit the transaction
  $dbh->commit;
};
if ($@) {
  # Error, so rollback and rethrow
  $dbh->rollback;
  die "$@";
}

# Disconnect from database
#
$dbh->disconnect;

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
