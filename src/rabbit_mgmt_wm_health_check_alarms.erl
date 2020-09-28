%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2007-2020 VMware, Inc. or its affiliates.  All rights reserved.
%%

%% An HTTP API counterpart of 'rabbitmq-dignoastics check_alarms'
-module(rabbit_mgmt_wm_health_check_alarms).

-export([init/2, to_json/2, content_types_provided/2, is_authorized/2]).
-export([resource_exists/2]).
-export([variances/2]).

-include_lib("rabbitmq_management_agent/include/rabbit_mgmt_records.hrl").

%%--------------------------------------------------------------------

init(Req, _State) ->
    {cowboy_rest, rabbit_mgmt_headers:set_common_permission_headers(Req, ?MODULE), #context{}}.

variances(Req, Context) ->
    {[<<"accept-encoding">>, <<"origin">>], Req, Context}.

content_types_provided(ReqData, Context) ->
   {rabbit_mgmt_util:responder_map(to_json), ReqData, Context}.

resource_exists(ReqData, Context) ->
    {true, ReqData, Context}.

to_json(ReqData, Context) ->
    Timeout = case cowboy_req:header(<<"timeout">>, ReqData) of
                  undefined -> 70000;
                  Val       -> list_to_integer(binary_to_list(Val))
              end,
    case rabbit_alarm:get_alarms(Timeout) of
        [] ->
            rabbit_mgmt_util:reply([{status, ok}], ReqData, Context);
        Xs when length(Xs) > 0 ->
            Msg = "There are alarms in effect in the cluster",
            failure(Msg, ReqData, Context)
    end.

failure(Message, ReqData, Context) ->
    {Response, ReqData1, Context1} = rabbit_mgmt_util:reply([{status, failed},
                                                             {reason, Message}],
                                                           ReqData, Context),
    {stop, cowboy_req:reply(500, #{}, Response, ReqData1), Context1}.

is_authorized(ReqData, Context) ->
    rabbit_mgmt_util:is_authorized(ReqData, Context).
