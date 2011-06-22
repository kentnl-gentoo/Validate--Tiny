#!/usr/bin/perl -T

use Test::More tests => 9;

use Validate::Tiny qw/validate :util/;

my ($input, $result, $rules);

SKIP: {
    eval("use Test::Exception");
    skip "Skipping sanity check. Test::Exception not installed.", 1 if $@;
    subtest 'Sanity check' => sub {
        dies_ok( sub { validate( {}, {} ) }, "Fields must be defined" );
        dies_ok(
            sub { validate( {}, { fields => [] } ) },
            "Fields can't be an empty array "
        );
        dies_ok( sub { validate( {}, { fields => {} } ) },
            "Fields must be an array" );
        dies_ok(
            sub {
                validate( {}, { fields => [qw/a/], filters => [ 1, 2, 3 ] } );
            },
            "Fields must have even number of elements"
        );
        dies_ok(
            sub { validate( {}, { fields => [qw/a/], checks => [ 1, 2, 3 ] } ) }
            ,
            "Checks must have even number of elements"
        );
        dies_ok(
            sub { validate( {}, { fields => [qw/a/], filters => { a => 1 } } ) }
            ,
            "Filters must be an arrayref"
        );
        dies_ok(
            sub { validate( {}, { fields => [qw/a/], checks => { a => 1 } } ) },
            "Checks must be an arrayref"
        );
        dies_ok(
            sub { validate( {}, { fields => [qw/a/], checks => [ a => 1 ] } ) },
            "Each check must be code or arrayref"
        );
        dies_ok(
            sub {
                validate( { a => 2 },
                    { fields => [qw/a/], filters => [ a => 1 ] } );
            },
            "Each filter must be code or arrayref"
        );
        dies_ok(
            sub {
                validate( {}, { fields => ['a'], something => [ 1, 2, 3 ] } );
            },
            "Checks for misspelled keys"
        );
    };
}

subtest 'Filters' => sub {
    my $ok = { success => 1, error => {}, data => { a => 'Jane Doe' } };
    $input = { a => '   Jane   Doe   ' };
    $rules = {
        fields  => [qw/a/],
        filters => [ a => [ filter('trim'), filter('strip') ] ]
    };
    is_deeply( validate( $input, $rules ), $ok, 'Filters 1' );

    ###

    $rules->{filters} = [ a => filter(qw/trim strip/) ];
    is_deeply( validate( $input, $rules ), $ok, 'Filters 2' );

    ###

    $rules->{filters} = [ a => [ filter(qw/trim strip/) ] ];
    is_deeply( validate( $input, $rules ), $ok, 'Filters 3' );

    ###

    $rules->{filters} = [
        a => sub {
            $_[0] =~ s/^\s+//;
            $_[0] =~ s/\s+$//;
            $_[0] =~ s/\s{2,}/ /g;
            return $_[0];
        }
    ];
    is_deeply( validate( $input, $rules ), $ok, 'Filters 4' );
};

subtest 'Checks' => sub {
    $rules = {
        fields => [qw/a b/],
        checks => [ [qw/a b/] => is_required() ]
    };
    is_deeply(
        validate( { a => '', b => 'something' }, $rules ),
        {
            success => 0,
            data    => { a => '', b => 'something' },
            error => { a => 'Required' }
        },
        'Check required 1'
    );

    ###

    is_deeply(
        validate( { a => 'something' }, $rules ),
        {
            success => 0,
            data    => { a => 'something' },
            error   => { b => 'Required' }
        },
        'Check required 2'
    );

    ###

    my $data = { a => 'a', b => 'b' };

    is_deeply(
        validate( $data, $rules ),
        {
            success => 1,
            data    => $data,
            error   => {}
        },
        'Check required 3'
    );

    ###

    $rules->{checks} = [ a => is_equal('b') ];
    is_deeply(
        validate( $data, $rules ),
        {
            success => 0,
            data    => $data,
            error   => { a => 'Invalid value' }
        },
        'Check equal 1'
    );

    ###

    $rules->{checks} = [ a => is_equal( 'b', 'Error' ) ];
    is_deeply(
        validate( $data, $rules ),
        {
            success => 0,
            data    => $data,
            error   => { a => 'Error' }
        },
        'Check equal 2'
    );

    ###

    is_deeply(
        validate( { a => 'a' }, $rules ),
        {
            success => 0,
            data    => { a => 'a' },
            error   => { a => 'Error' }
        },
        'Check equal 3'
    );

    ###

    is_deeply(
        validate( { b => 'a', a => 'a' }, $rules ),
        {
            success => 1,
            data    => { a => 'a', b => 'a' },
            error   => {}
        },
        'Check equal 4'
    );

    ###

    is_deeply(
        validate( { b => 'a' }, $rules ),
        {
            success => 1,
            data    => { b => 'a' },
            error   => {}
        },
        'Check equal 5'
    );

    ###

    $result = validate(
        { a => 20 },
        {
            fields => [qw/a/],
            checks => [ a => sub { $_[0] < 12 ? undef : 'Error' } ]
        }
    );
    is_deeply(
        $result,
        {
            success => 0,
            data    => { a => 20 },
            error   => { a => 'Error' }
        },
        'Custom check 1'
    );

};

subtest 'Non-required params' => sub {
    $result = validate(
        { a => 1, b => 0 },
        {
            fields => [qw/a b c/],
            checks => [
                a         => is_required(),
                [qw/b c/] => sub {
                    if ( defined $_[0] ) {
                        $_[0] > 1 ? undef : 'Error';
                    }
                    else {
                        return undef;
                    }
                  }
            ]
        }
    );
    is_deeply(
        $result,
        {
            success => 0,
            data    => { a => 1, b => 0 },
            error => { b => 'Error' }
        },
        "Fail checks if provided"
    );

    $result = validate(
        { a => 1 },
        {
            fields => [qw/a b c/],
            checks => [
                a         => is_required(),
                [qw/b c/] => sub {
                    if ( defined $_[0] ) {
                        $_[0] > 1 ? undef : 'Error';
                    }
                    else {
                        return undef;
                    }
                  }
            ]
        }
    );
    is_deeply(
        $result,
        {
            success => 1,
            data    => { a => 1 },
            error   => {}
        },
        "Pass checks if undefined"
    );
};

subtest 'Params' => sub {
    $result = validate(
        { a => 1 },
        {
            fields => [qw/a b c/],
            checks => [ a => sub { $_[0] < 12 ? undef : 'Error' } ]
        }
    );
    is_deeply(
        $result,
        {
            success => 1,
            data    => { a => 1 },
            error   => {}
        },
        'Missing params not checked'
    );

    $result = validate(
        { a => '', b => '   ' },
        {
            fields  => [qw/a b c/],
            filters => [ [qw/a b c/] => filter(qw/trim strip/) ],
            checks  => [ [qw/a b c/] => is_required() ]
        }
    );
    is_deeply(
        $result,
        {
            success => 0,
            data    => { a => '', b => '' },
            error   => { a => 'Required', b => 'Required', c => 'Required' }
        },
        'Required params failed'
    );
};

subtest 'Check arrays' => sub {
    $input = { a => [ 1, 2, 3, 4 ] };
    $rules = {
        fields  => [qw/a/],
        filters => [
            a => sub {
                [ grep { $_ > 2 } @{ $_[0] } ];
              }
        ],
        checks => [
            a => sub {
                for ( @{ $_[0] } ) { return 'Error' if $_ > 5 }
                undef;
              }
        ]
    };

    $result = validate( $input, $rules );
    is_deeply(
        $result,
        {
            success => 1,
            data    => { a => [ 3, 4 ] },
            error   => {}
        },
        'Proper array filter and check OK'
    );

    $input = { a => [ 1, 2, 3, 4, 20, 30 ] };
    $result = validate( $input, $rules );
    is_deeply(
        $result,
        {
            success => 0,
            data    => { a => [ 3, 4, 20, 30 ] },
            error => { a => 'Error' }
        },
        'Bad array fails OK'
    );
};

# is_long_between()
#

subtest is_long_between => sub {
    $input = { a => '12345' };
    $rules = {
        fields => [qw/a/],
        checks => [ a => is_long_between( 3, 5 ) ]
    };

    is_deeply(
        validate( $input, $rules ),
        { success => 1, data => { a => '12345' }, error => {} },
        "is_long_between() test 1"
    );

    $input = { a => '123456' };
    is_deeply(
        validate( $input, $rules ),
        {
            success => 0,
            data    => { a => '123456' },
            error   => { a => 'Must be between 3 and 5 symbols' }
        },
        "is_long_between() test 2"
    );

    $rules->{checks} = [ a => is_long_between( 3, 5, 'Error' ) ];
    is_deeply(
        validate( $input, $rules ),
        {
            success => 0,
            data    => { a => '123456' },
            error   => { a => 'Error' }
        },
        "is_long_between() test 3"
    );
};

# is_long_at_least
#

subtest is_long_at_least => sub {
    $input = { a => '12345' };
    $rules = {
        fields => [qw/a/],
        checks => [ a => is_long_at_least( 5 ) ]
    };

    is_deeply(
        validate( $input, $rules ),
        { success => 1, data => { a => '12345' }, error => {} },
        "is_long_at_least() test 1"
    );

    $input = { a => '12' };
    is_deeply(
        validate( $input, $rules ),
        {
            success => 0,
            data    => { a => '12' },
            error   => { a => 'Must be at least 5 symbols' }
        },
        "is_long_at_least() test 2"
    );

    $rules->{checks} = [ a => is_long_at_least( 5, 'Error' ) ];
    is_deeply(
        validate( $input, $rules ),
        {
            success => 0,
            data    => { a => '12' },
            error   => { a => 'Error' }
        },
        "is_long_at_least() test 3"
    );
};

# is_long_at_most
#

subtest is_long_at_most => sub {
    $input = { a => '12345' };
    $rules = {
        fields => [qw/a/],
        checks => [ a => is_long_at_most( 5 ) ]
    };

    is_deeply(
        validate( $input, $rules ),
        { success => 1, data => { a => '12345' }, error => {} },
        "is_long_at_most() test 1"
    );

    $input = { a => '1234567' };
    is_deeply(
        validate( $input, $rules ),
        {
            success => 0,
            data    => { a => '1234567' },
            error   => { a => 'Must be at the most 5 symbols' }
        },
        "is_long_at_most() test 2"
    );

    $rules->{checks} = [ a => is_long_at_most( 5, 'Error' ) ];
    is_deeply(
        validate( $input, $rules ),
        {
            success => 0,
            data    => { a => '1234567' },
            error   => { a => 'Error' }
        },
        "is_long_at_most() test 3"
    );
};

