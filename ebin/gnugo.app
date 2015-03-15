{application, gnugo,
 [{description, "An Erlang interface to GNU Go"},
  {vsn, "0.0.1"},
  {modules, [ gnugo
            , gtp
            ]},
  {registered, []},
  {applications, [ kernel
                 , stdlib
                 ]},
  {env, []}
 ]}.
