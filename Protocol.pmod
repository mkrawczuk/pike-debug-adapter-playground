//
// Base Protocol, DAP's communication protocol helper functions:
//

string parse_request(string data) {
    Stdio.Buffer ibuf = Stdio.Buffer();
    ibuf->add(data);
    int length;
    [length] = ibuf->sscanf("Content-Length: %d\r\n\r\n");

    return ibuf->read(length);
}

string encode_message(ProtocolMessage msg) {
    String.Buffer sbuf = String.Buffer();

    string enc = Standards.JSON.encode(msg);
    sbuf->sprintf("Content-Length: %d\r\n\r\n%s", sizeof(enc), enc);
    return sbuf->get();
}

//
// Debug Adapter Protocol
//

class JsonEncodable() {
    protected mapping(string:mixed) to_json();

    string encode_json() {
        return Standards.JSON.encode(to_json());
    }
}

// Base class of requests, responses, and events.
class ProtocolMessage {
    inherit JsonEncodable;

    int    seq;  // json: "seq"
    string type; // json: "type"

    protected void create(mixed|void json) {
        if (!json) return;

        seq = json["seq"];
        type = json["type"];
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ([
            "seq" : seq,
            "type" : type,
        ]);

        return json;
    }
}

// A debug adapter initiated event.
class Event {
    inherit ProtocolMessage;

    mixed  body;  // json: "body"
    string event; // json: "event"

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            body = json["body"];
            event = json["event"];
        }

        type = "event";
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "body" : body,
            "event" : event,
        ]);

        return json;
    }
}

// A client or debug adapter initiated request.
class Request {
    inherit ProtocolMessage;

    string command; // json: "command"

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            command = json["command"];
        }

        type = "request";
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "command" : command,
        ]);

        return json;
    }
}

// Response for a request.
class Response {
    inherit ProtocolMessage;

    mixed  body;        // json: "body"
    string command;     // json: "command"
    string message;     // json: "message"
    int    request_seq; // json: "request_seq"
    int    success;     // json: "success"

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            body = json["body"];
            command = json["command"];
            message = json["message"];
            request_seq = json["request_seq"];
            success = json["success"];
        }

        type = "response";
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "body" : body,
            "command" : command,
            "message" : message,
            "request_seq" : request_seq,
            "success" : success,
        ]);

        return json;
    }
}

// This event indicates that the debug adapter is ready to accept configuration requests
// (e.g. SetBreakpointsRequest, SetExceptionBreakpointsRequest).
// A debug adapter is expected to send this event when it is ready to accept configuration
// requests (but not before the 'initialize' request has finished).
// The sequence of events/requests is as follows:
// - adapters sends 'initialized' event (after the 'initialize' request has returned)
// - frontend sends zero or more 'setBreakpoints' requests
// - frontend sends one 'setFunctionBreakpoints' request
// - frontend sends a 'setExceptionBreakpoints' request if one or more
// 'exceptionBreakpointFilters' have been defined (or if 'supportsConfigurationDoneRequest'
// is not defined or false)
// - frontend sends other future configuration requests
// - frontend sends one 'configurationDone' request to indicate the end of the configuration.
class InitializedEvent {
    inherit Event;

    protected void create (mixed|void json) {

        if (json) ::create(json);
        else ::create();

        event = "initialized";
    }
}

class StoppedEvent {
    inherit Event;

    mixed body;

    protected void create (mixed|void json) {
        if (json) ::create(json);
        else ::create();

        event = "stopped";
    }
    mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "body" : body,
        ]);

        return json;
    }
}
// The 'initialize' request is sent as the first request from the client to the debug
// adapter in order to configure it with client capabilities and to retrieve capabilities
// from the debug adapter.
// Until the debug adapter has responded to with an 'initialize' response, the client must
// not send any additional requests or events to the debug adapter. In addition the debug
// adapter is not allowed to send any requests or events to the client until it has
// responded with an 'initialize' response.
// The 'initialize' request may only be sent once.
class InitializeRequest {
    inherit Request;

    InitializeRequestArguments arguments; // json: "arguments"

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            arguments = InitializeRequestArguments(json["arguments"]);
        }
        else {
            ::create();
            arguments = InitializeRequestArguments();
        };

        command = "initialize";
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "arguments" : arguments,
        ]);

        return json;
    }
}

// Arguments for 'initialize' request.
class InitializeRequestArguments {
    inherit JsonEncodable;

    string adapter_id;                       // json: "adapterID"
    string client_id;                        // json: "clientID"
    string client_name;                      // json: "clientName"
    int    columns_start_at1;                // json: "columnsStartAt1"
    int    lines_start_at1;                  // json: "linesStartAt1"
    string locale;                           // json: "locale"
    string path_format;                      // json: "pathFormat"
    int    supports_run_in_terminal_request; // json: "supportsRunInTerminalRequest"
    int    supports_variable_paging;         // json: "supportsVariablePaging"
    int    supports_variable_type;           // json: "supportsVariableType"

    protected void create(mixed|void json) {
        if (!json) return;

        adapter_id = json["adapterID"];
        client_id = json["clientID"];
        client_name = json["clientName"];
        columns_start_at1 = json["columnsStartAt1"];
        lines_start_at1 = json["linesStartAt1"];
        locale = json["locale"];
        path_format = json["pathFormat"];
        supports_run_in_terminal_request = json["supportsRunInTerminalRequest"];
        supports_variable_paging = json["supportsVariablePaging"];
        supports_variable_type = json["supportsVariableType"];
    }

    string to_json() {
        mapping(string:mixed) json = ([
            // no need to explicitly disable options
            //
            // "adapterID" : adapter_id,
            // "clientID" : client_id,
            // "clientName" : client_name,
            // "columnsStartAt1" : columns_start_at1,
            // "linesStartAt1" : lines_start_at1,
            // "locale" : locale,
            // "pathFormat" : path_format,
            // "supportsRunInTerminalRequest" : supports_run_in_terminal_request,
            // "supportsVariablePaging" : supports_variable_paging,
            // "supportsVariableType" : supports_variable_type,
        ]);

        return Standards.JSON.encode(json);
    }
}

// Response to 'initialize' request.
class InitializeResponse {
    inherit Response;

    Capabilities body;

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            body = Capabilities(json["body"]);
        } else {
            ::create();
            body = Capabilities();

        }
        command = "initialize";
    }

    mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "body" : body,
        ]);

        return json;
    }
}

// Information about the capabilities of a debug adapter.
class Capabilities {
    inherit JsonEncodable;

    // json: "additionalModuleColumns"
    array(ColumnDescriptor) additional_module_columns = ({});
    // json: "exceptionBreakpointFilters"
    array(ExceptionBreakpointsFilter) exception_breakpoint_filters = ({});
    // json: "supportedChecksumAlgorithms"
    array(string) supported_checksum_algorithms = ({});
    int supports_completions_request;         // json: "supportsCompletionsRequest"
    int supports_conditional_breakpoints;     // json: "supportsConditionalBreakpoints"
    int supports_configuration_done_request;  // json: "supportsConfigurationDoneRequest"
    int supports_delayed_stack_trace_loading; // json: "supportsDelayedStackTraceLoading"
    int supports_evaluate_for_hovers;         // json: "supportsEvaluateForHovers"
    int supports_exception_info_request;      // json: "supportsExceptionInfoRequest"
    int supports_exception_options;           // json: "supportsExceptionOptions"
    int supports_function_breakpoints;        // json: "supportsFunctionBreakpoints"
    int supports_goto_targets_request;        // json: "supportsGotoTargetsRequest"
    int supports_hit_conditional_breakpoints; // json: "supportsHitConditionalBreakpoints"
    int supports_loaded_sources_request;      // json: "supportsLoadedSourcesRequest"
    int supports_log_points;                  // json: "supportsLogPoints"
    int supports_modules_request;             // json: "supportsModulesRequest"
    int supports_restart_frame;               // json: "supportsRestartFrame"
    int supports_restart_request;             // json: "supportsRestartRequest"
    int supports_set_expression;              // json: "supportsSetExpression"
    int supports_set_variable;                // json: "supportsSetVariable"
    int supports_step_back;                   // json: "supportsStepBack"
    int supports_step_in_targets_request;     // json: "supportsStepInTargetsRequest"
    int supports_terminate_request;           // json: "supportsTerminateRequest"
    int supports_terminate_threads_request;   // json: "supportsTerminateThreadsRequest"
    int supports_value_formatting_options;    // json: "supportsValueFormattingOptions"
    int supports_terminate_debuggee;           // json: "supportTerminateDebuggee"

    protected void create(mixed|void json) {
        if (!json) return;

        additional_module_columns = map(json["additionalModuleColumns"], ColumnDescriptor);
        exception_breakpoint_filters = map(json["exceptionBreakpointFilters"], ExceptionBreakpointsFilter);
        supported_checksum_algorithms = json["supportedChecksumAlgorithms"];
        supports_completions_request = json["supportsCompletionsRequest"];
        supports_conditional_breakpoints = json["supportsConditionalBreakpoints"];
        supports_configuration_done_request = json["supportsConfigurationDoneRequest"];
        supports_delayed_stack_trace_loading = json["supportsDelayedStackTraceLoading"];
        supports_evaluate_for_hovers = json["supportsEvaluateForHovers"];
        supports_exception_info_request = json["supportsExceptionInfoRequest"];
        supports_exception_options = json["supportsExceptionOptions"];
        supports_function_breakpoints = json["supportsFunctionBreakpoints"];
        supports_goto_targets_request = json["supportsGotoTargetsRequest"];
        supports_hit_conditional_breakpoints = json["supportsHitConditionalBreakpoints"];
        supports_loaded_sources_request = json["supportsLoadedSourcesRequest"];
        supports_log_points = json["supportsLogPoints"];
        supports_modules_request = json["supportsModulesRequest"];
        supports_restart_frame = json["supportsRestartFrame"];
        supports_restart_request = json["supportsRestartRequest"];
        supports_set_expression = json["supportsSetExpression"];
        supports_set_variable = json["supportsSetVariable"];
        supports_step_back = json["supportsStepBack"];
        supports_step_in_targets_request = json["supportsStepInTargetsRequest"];
        supports_terminate_request = json["supportsTerminateRequest"];
        supports_terminate_threads_request = json["supportsTerminateThreadsRequest"];
        supports_value_formatting_options = json["supportsValueFormattingOptions"];
        supports_terminate_debuggee = json["supportsTerminateDebuggee"];
    }

    mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ([
            // "additionalModuleColumns" : additional_module_columns,
            // "exceptionBreakpointFilters" : exception_breakpoint_filters,
            // "supportedChecksumAlgorithms" : supported_checksum_algorithms,
            // "supportsCompletionsRequest" : supports_completions_request,
            // "supportsConditionalBreakpoints" : supports_conditional_breakpoints,
            "supportsConfigurationDoneRequest" : supports_configuration_done_request,
            // "supportsDelayedStackTraceLoading" : supports_delayed_stack_trace_loading,
            // "supportsEvaluateForHovers" : supports_evaluate_for_hovers,
            // "supportsExceptionInfoRequest" : supports_exception_info_request,
            // "supportsExceptionOptions" : supports_exception_options,
            // "supportsFunctionBreakpoints" : supports_function_breakpoints,
            // "supportsGotoTargetsRequest" : supports_goto_targets_request,
            // "supportsHitConditionalBreakpoints" : supports_hit_conditional_breakpoints,
            // "supportsLoadedSourcesRequest" : supports_loaded_sources_request,
            // "supportsLogPoints" : supports_log_points,
            // "supportsModulesRequest" : supports_modules_request,
            // "supportsRestartFrame" : supports_restart_frame,
            // "supportsRestartRequest" : supports_restart_request,
            // "supportsSetExpression" : supports_set_expression,
            // "supportsSetVariable" : supports_set_variable,
            // "supportsStepBack" : supports_step_back,
            // "supportsStepInTargetsRequest" : supports_step_in_targets_request,
            // "supportsTerminateRequest" : supports_terminate_request,
            // "supportsTerminateThreadsRequest" : supports_terminate_threads_request,
            // "supportsValueFormattingOptions" : supports_value_formatting_options,
            // "supportsTerminateDebuggee" : supports_terminate_debuggee,
        ]);

        return json;
    }
}

// A ColumnDescriptor specifies what module attribute to show in a column of the
// ModulesView, how to format it, and what the column's label should be.
// It is only used if the underlying UI actually supports this level of customization.
class ColumnDescriptor {
    inherit JsonEncodable;

    string attribute_name; // json: "attributeName"
    int  format;         // json: "format"
    string label;          // json: "label"
    string type;           // json: "type"
    int    width;          // json: "width"

    protected void create(mixed|void json) {
        if (!json) return;

        attribute_name = json["attributeName"];
        format = json["format"];
        label = json["label"];
        type = json["type"];
        width = json["width"];
    }

    mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ([
            "attributeName" : attribute_name,
            "format" : format,
            "label" : label,
            "type" : type,
            "width" : width,
        ]);

        return json;
    }
}

// An ExceptionBreakpointsFilter is shown in the UI as an option for configuring how
// exceptions are dealt with.
class ExceptionBreakpointsFilter {
    inherit JsonEncodable;

    int    is_default; // json: "default"
    string filter;     // json: "filter"
    string label;      // json: "label"

    protected void create(mixed|void json) {
        if (!json) return;

        is_default = json["default"];
        filter = json["filter"];
        label = json["label"];
    }

    mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ([
            "default" : is_default,
            "filter" : filter,
            "label" : label,
        ]);

        return json;
    }
}

// The attach request is sent from the client to the debug adapter to attach to a debuggee
// that is already running. Since attaching is debugger/runtime specific, the arguments for
// this request are not part of this specification.
class AttachRequest {
    inherit Request;

    mixed arguments; // these are implementation-specific. json: "arguments"

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            arguments = json["arguments"];
        }
        else ::create();

        command = "attach";
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "arguments" : arguments,
        ]);

        return json;
    }
}

// Response to 'attach' request. This is just an acknowledgement, so no body field is
// required.
class AttachResponse {
        inherit Response;

    protected void create(mixed|void json) {
        if (json) ::create(json);
        else ::create();

        command = "attach";
    }
}

// The launch request is sent from the client to the debug adapter to start the debuggee
// with or without debugging (if 'noDebug' is true). Since launching is debugger/runtime
// specific, the arguments for this request are not part of this specification.
class LaunchRequest {
    inherit Request;

    mixed arguments; // these are implementation-specific. json: "arguments"

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            arguments = json["arguments"];
        }
        else ::create();

        command = "launch";
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "arguments" : arguments,
        ]);

        return json;
    }
}

// Response to 'launch' request. This is just an acknowledgement, so no body field is
// required.
class LaunchResponse {
        inherit Response;

    protected void create(mixed|void json) {
        if (json) ::create(json);
        else ::create();

        command = "launch";
    }
}
// Evaluates the given expression in the context of the top most stack frame.
// The expression has access to any variables and arguments that are in scope.
class EvaluateRequest {
    inherit Request;

    EvaluateArguments arguments; // json: "arguments"

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            arguments = EvaluateArguments(json["arguments"]);
        } else {
            ::create();
            arguments = EvaluateArguments();
        }

        command = "evaluate";
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ::to_json();
        json += ([
            "arguments" : arguments,
        ]);

        return json;
    }
}

// Arguments for 'evaluate' request.
class EvaluateArguments {
    mixed  context;    // json: "context"
    string expression; // json: "expression"
    mixed  format;     // json: "format"
    mixed  frame_id;   // json: "frameId"

    protected void create(mixed|void json) {
        if (!json) return;

        context = json["context"];
        expression = json["expression"];
        format = json["format"];
        frame_id = json["frameId"];
    }

    protected mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ([
                "context" : context,
                "expression" : expression,
                "format" : format,
                "frameId" : frame_id,    ]);

        return json;
    }
}

// Response to 'evaluate' request.
class EvaluateResponse {
    inherit Response;

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            body = json["body"];
        } else ::create();

        command = "evaluate";
    }
}

// Response to 'threads' request.
class ThreadsResponse {
    inherit Response;

    protected void create(mixed|void json) {
        if (json) {
            ::create(json);
            body = json["body"];
        }
        else ::create();

        command = "threads";
    }
}

// A Thread.
class DAPThread {
    inherit JsonEncodable;

    int    id;   // json: "id"
    string name; // json: "name"

    protected void create(mixed|void json) {
        if (!json) return;

        id = json["id"];
        name = json["name"];

    }

    mapping(string:mixed) to_json() {
        mapping(string:mixed) json = ([
            "id" : id,
            "name" : name
        ]);

        return json;
    }
}