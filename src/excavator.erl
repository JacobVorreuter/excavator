%% Copyright (c) 2009 Jacob Vorreuter <jacob.vorreuter@gmail.com>
%% 
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%% 
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.
-module(excavator).
-behaviour(application).

-export([start/2,stop/1, init/1]).
-export([stop/0, build_rel/0]).

stop() ->
    [Node | _] = init:get_plain_arguments(),
    Resp = rpc:call(list_to_atom(Node), init, stop, []),
    Resp.

start(_, _) ->
    LogLevel =
        case application:get_env(excavator, log_level) of
            {ok, L} -> L;
            undefined -> info
        end,
    ex_loglevel:set(LogLevel),
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

stop(_) ->
    ok.

init(_) ->
   {ok, {{one_for_one, 10, 10}, [
       {ex_scheduler, {ex_scheduler, start_link, []}, permanent, 5000, worker, [ex_scheduler]}
   ]}}.

build_rel() ->
    {ok, FD} = file:open("excavator.rel", [write]),
    RelInfo = {release,
        {"excavator", "0.3"},
        {erts, "5.7.2"}, [
            {kernel, "2.13.2"},
            {stdlib, "1.16.2"},
            {sasl, "2.1.6"},
            {crypto, "1.6"},
			{inets, "5.1"},
            {mochiweb, "0.2"},
            {mochixpath, "0.1"},
            {dynamic_compile, "0.1"},
            {excavator, "0.3"}
        ]
    },
    io:format(FD, "~p.", [RelInfo]),
    file:close(FD),
    systools:make_script("excavator", [local]),
    ok.