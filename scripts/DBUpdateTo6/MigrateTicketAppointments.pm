# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::DBUpdateTo6::MigrateTicketAppointments;    ## no critic

use strict;
use warnings;

use parent qw(scripts::DBUpdateTo6::Base);

our @ObjectDependencies = (
    'Kernel::System::Calendar',
);

=head1 NAME

scripts::DBUpdateTo6::MigrateTicketAppointments - Migrate ticket appointment rules to new ticket search article field
names.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $CalendarObject = $Kernel::OM->Get('Kernel::System::Calendar');

    my @Calendars = $CalendarObject->CalendarList();

    CALENDAR:
    for my $Calendar (@Calendars) {
        my %Calendar = $CalendarObject->CalendarGet(
            CalendarID => $Calendar->{CalendarID},
        );

        next CALENDAR if !defined $Calendar{TicketAppointments};

        my $UpdateNeeded;

        RULE:
        for my $TicketAppointmentRule ( @{ $Calendar{TicketAppointments} // [] } ) {
            next RULE if !$TicketAppointmentRule->{SearchParam};

            # Rename old-style article fields in search parameters.
            my %SearchParamMap = (
                AttachmentName => 'MIMEBase_AttachmentName',
                Body           => 'MIMEBase_Body',
                Cc             => 'MIMEBase_Cc',
                From           => 'MIMEBase_From',
                Subject        => 'MIMEBase_Subject',
                To             => 'MIMEBase_To',
            );
            SEARCH_PARAM:
            for my $SearchParam ( sort keys %{ $TicketAppointmentRule->{SearchParam} // {} } ) {
                next SEARCH_PARAM if !$SearchParamMap{$SearchParam};

                $TicketAppointmentRule->{SearchParam}->{ $SearchParamMap{$SearchParam} }
                    = $TicketAppointmentRule->{SearchParam}->{$SearchParam};

                delete $TicketAppointmentRule->{SearchParam}->{$SearchParam};

                $UpdateNeeded = 1;
            }
        }

        next CALENDAR if !$UpdateNeeded;

        my $Success = $CalendarObject->CalendarUpdate(
            %Calendar,
            UserID => 1,
        );
        if ( !$Success ) {
            print "\n  Could not update calendar '$Calendar{CalendarName}'.\n";
            return;
        }
    }

    return 1;
}

=head2 CheckPreviousRequirement()

check for initial conditions for running this migration step.

Returns 1 on success

    my $Result = $DBUpdateTo6Object->CheckPreviousRequirement();

=cut

sub CheckPreviousRequirement {
    my ( $Self, %Param ) = @_;

    # Check if possible create required object,
    # that means the calendar module
    # is in the system
    my $AppointmentCalendarObject = $Kernel::OM->Get('Kernel::System::Calendar');
    if ( !$AppointmentCalendarObject ) {
        print "Error: Not possible to create calendar object!";
        return;
    }

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
