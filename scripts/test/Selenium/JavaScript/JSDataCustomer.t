# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));
use Time::HiRes qw(sleep);

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get needed objects
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::UnitTest::Helper' => {
                RestoreSystemConfiguration => 1,
            },
        );

        my $Helper          = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
        my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');

        my @Tests = (
            {
                Key           => 'UserLanguage',
                ExpectedValue => 'en',
                Environment   => 1,
            },
            {
                Key           => 'Action',
                ExpectedValue => 'CustomerTicketMessage',
                Environment   => 1,
            },
            {
                Key           => 'Frontend::WebPath',
                JSKey         => 'WebPath',
                ExpectedValue => $ConfigObject->Get('Frontend::WebPath'),
                Environment   => 1,
            },
            {
                Key           => 'CustomerPanelSessionName',
                ExpectedValue => 'OTRSUTValue',
            },
            {
                Key           => 'CheckEmailAddresses',
                ExpectedValue => '3',
            },
            {
                Key           => 'Frontend::AnimationEnabled',
                JSKey         => 'AnimationEnabled',
                ExpectedValue => '6',
            },
            {
                Key           => 'ModernizeCustomerFormFields',
                JSKey         => 'InputFieldsActivated',
                ExpectedValue => '9',
            },
        );

        # set the expected values
        TEST:
        for my $Test (@Tests) {

            next TEST if $Test->{Environment};

            # set the item to the expected value
            $SysConfigObject->ConfigItemUpdate(
                Valid => 1,
                Key   => $Test->{Key},
                Value => $Test->{ExpectedValue}
            );
        }

        # create test customer user
        my $TestCustomerUserLogin = $Helper->TestCustomerUserCreate(
        ) || die "Did not get test customer user";

        # login test customer user
        $Selenium->Login(
            Type     => 'Customer',
            User     => $TestCustomerUserLogin,
            Password => $TestCustomerUserLogin,
        );

        # get script alias
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        $Selenium->VerifiedGet("${ScriptAlias}customer.pl?Action=CustomerTicketMessage");

        for my $Test (@Tests) {

            my $Key = $Test->{JSKey} // $Test->{Key};

            # check value
            $Self->Is(
                $Selenium->execute_script(
                    "return Core.Config.Get('$Key');"
                ),
                $Test->{ExpectedValue},
                "$Key matches expected value.",
            );
        }
    }
);

1;
