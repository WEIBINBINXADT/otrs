# --
# Kernel/System/Auth/DB.pm - provides the db authentification 
# Copyright (C) 2002 Martin Edenhofer <martin+code@otrs.org>
# --
# $Id: DB.pm,v 1.1 2002-07-23 22:12:22 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see 
# the enclosed file COPYING for license information (GPL). If you 
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --
# Note: 
# available objects are: ConfigObject, LogObject and DBObject
# --

package Kernel::System::Auth::DB;

use strict;

use vars qw($VERSION);
$VERSION = '$Revision: 1.1 $';
$VERSION =~ s/^.*:\s(\d+\.\d+)\s.*$/$1/;

# --
sub Auth {
    my $Self = shift;
    my %Param = @_;
    # --
    # check needed stuff
    # --
    if (!$Param{User}) {
      $Self->{LogObject}->Log(Priority => 'error', Message => "Need User!");
      return;
    }
    # --
    # get params
    # --
    my $User = $Param{User} || ''; 
    my $Pw = $Param{Pw} || '';
    my $RemoteAddr = $ENV{REMOTE_ADDR} || 'Got no REMOTE_ADDR env!';
    my $UserID = '';
    my $GetPw = '';

    # --
    # get user table
    # --
    $Self->{UserTable} = $Self->{ConfigObject}->Get('DatabaseUserTable')
      || 'user';
    $Self->{UserTableUserID} = $Self->{ConfigObject}->Get('DatabaseUserTableUserID')
      || 'id';
    $Self->{UserTableUserPW} = $Self->{ConfigObject}->Get('DatabaseUserTableUserPW')
      || 'pw';
    $Self->{UserTableUser} = $Self->{ConfigObject}->Get('DatabaseUserTableUser')
      || 'login';

    # --
    # sql query
    # --
    my $SQL = "SELECT $Self->{UserTableUserPW}, $Self->{UserTableUserID} ".
      " FROM ".
      " $Self->{UserTable} ".
      " WHERE ". 
      " valid_id in ( ${\(join ', ', $Self->{DBObject}->GetValidIDs())} ) ".
      " AND ".
      " $Self->{UserTableUser} = '$User'";
    $Self->{DBObject}->Prepare(SQL => $SQL);
    while (my @RowTmp = $Self->{DBObject}->FetchrowArray()) { 
        $GetPw = $RowTmp[0];
        $UserID = $RowTmp[1];
    }

    # --
    # just in case!
    # --
    if ($Self->{Debug} > 0) {
        $Self->{LogObject}->Log(
          Priority => 'notice',
          Message => "User: '$User' tried to login with Pw: '$Pw' ($UserID/$GetPw/$RemoteAddr)",
        );
    }

    # --
    # just a note 
    # --
    if (!$Pw) {
        $Self->{LogObject}->Log(
          Priority => 'notice',
          Message => "User: $User without Pw!!! (REMOTE_ADDR: $RemoteAddr)",
        );
        return;
    }
    # --
    # login note
    # --
    elsif ((($GetPw)&&($User)&&($UserID)) && crypt($Pw, $User) eq $GetPw) {
        $Self->{LogObject}->Log(
          Priority => 'notice',
          Message => "User: $User logged in (REMOTE_ADDR: $RemoteAddr).",
        );
        return 1;
    }
    # --
    # just a note
    # --
    elsif (($UserID) && ($GetPw)) {
        $Self->{LogObject}->Log(
          Priority => 'notice',
          Message => "User: $User with wrong Pw!!! (REMOTE_ADDR: $RemoteAddr)"
        ); 
        return;
    }
    # --
    # just a note
    # --
    else {
        $Self->{LogObject}->Log(
          Priority => 'notice',
          Message => "User: $User doesn't exist or is invalid!!! (REMOTE_ADDR: $RemoteAddr)"
        ); 
        return;
    }
}
# --

1;

