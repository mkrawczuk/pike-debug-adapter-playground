#define DEBUG(X, Y ...) do { if (debug) werror(X, Y); } while (0)
#define DEFAULT_PORT 4711

import .Protocol;

bool debug;
bool im_a_server;
Stdio.File client;
Stdio.Buffer obuf = Stdio.Buffer();

void write_event(ProtocolMessage msg) {
    string msg_str = encode_message(msg);

    DEBUG("\nSending event: \n%s\n", msg_str);

    if (im_a_server) obuf->add(msg_str);
    else obuf->write(msg_str);
}

void write_response(ProtocolMessage msg) {
    string msg_str = encode_message(msg);

    DEBUG("\nSending response: \n%s\n", msg_str);

    if (im_a_server) client->write(msg_str);
    else obuf->write(msg_str);
}

void handle_initialize_request(mixed msg) {
    InitializeRequest req = InitializeRequest(msg);
    InitializeResponse res = InitializeResponse();

    res->body->supports_configuration_done_request = 1;
    res->request_seq = req->seq;
    res->success = 1;

    write_response(res);

    InitializedEvent evt = InitializedEvent();

    write_event(evt);
}

void handle_attach_request(mixed msg) {
    AttachRequest req = AttachRequest(msg);
    AttachResponse res = AttachResponse();

    res->request_seq = req->seq;
    res->success = 1;

    write_response(res);
}

void handle_launch_request(mixed msg) {
    LaunchRequest req = LaunchRequest(msg);
    LaunchResponse res = LaunchResponse();

    res->request_seq = req->seq;
    res->success = 1;

    write_response(res);
}

void handle_evaluate_request(mixed msg) {
    EvaluateRequest req = EvaluateRequest(msg);
    Response res = Response();

    res->request_seq = req->seq;
    res->success = 1;
    res->body = ([
        "result" : "EvaluateResponse echo: " + req?->arguments?->expression,
        "variablesReference" : 0
    ]);

    write_response(res);
}

void handle_threads_request(mixed msg) {
    Request req = Request(msg);
    ThreadsResponse res = ThreadsResponse();

    DAPThread dt = DAPThread();
    dt->id = 1;
    dt->name = "dummy";

    res->body = (["threads" : ({ dt })]);

    res->request_seq = req->seq;
    res->success = 1;

    write_response(res);
}

void handle_configuration_done_request(mixed msg) {
    Request req = Request(msg);
    Response res = Response();

    res->request_seq = req->seq;
    res->success = 1;
    res->command = req->command;


    write_response(res);
    StoppedEvent evt = StoppedEvent();
    evt->body = (["reason" : "entry", "threadId" : 1]);
    write_event(evt);
}

void handle_stack_trace_request(mixed msg) {
    Request req = Request(msg);
    Response res = Response();

    res->request_seq = req->seq;
    res->success = 1;
    res->command = req->command;

    res->body = ([
        "stackFrames" : ({
            ([
                "id" : 0,
                "line" : 0,
                "column" : 0,
                "name" : "Stack frame 1"
            ])
        })
    ]);

    write_response(res);
}

void handle_scopes_request(mixed msg) {
    Request req = Request(msg);
    Response res = Response();

    res->request_seq = req->seq;
    res->success = 1;
    res->command = req->command;
    res->body = ([
        "scopes" : ({
            ([
                "name" : "scope name",
                "variableReference" : "variable reference",
                "expensive" : false
            ])
        })
    ]);
    write_response(res);
}

void handle_action_request(mixed msg) {
    handle_request_generic(msg);
    
    StoppedEvent evt = StoppedEvent();
    evt->body = (["reason" : "pause", "threadId" : 1]);
    sleep(0.5);
    write_event(evt);
}

void handle_request_generic(mixed msg) {
    Request req = Request(msg);
    Response res = Response();

    res->request_seq = req->seq;
    res->success = 1;
    res->command = req->command;

    write_response(res);
}

private void close_cb(mixed data)
{
    DEBUG("\nClose callback. Shutting down.\n");
    exit(0);
}


private void write_cb(mixed id)
{
    if (im_a_server) {
        string m = obuf->read();
        if (sizeof(m)) client->write(m);
    }
}

private void read_cb(mixed id, string data)
{
    mixed msg = Standards.JSON.decode(parse_request(data));
    DEBUG("\nReceived request: \n%s\n", data);
    switch (msg[?"command"]) {
        case "initialize":
            handle_initialize_request(msg);
            break;
        case "attach":
            handle_attach_request(msg);
            break;
        case "launch":
            handle_launch_request(msg);
            break;
        case "evaluate":
            handle_evaluate_request(msg);
            break;
        case "threads":
            handle_threads_request(msg);
            break;
        case "configurationDone":
            handle_configuration_done_request(msg);
            break;
        case "stackTrace":
            handle_stack_trace_request(msg);
            break;
        case "scopes":
            handle_scopes_request(msg);
            break;
        case "continue":
        case "next":
        case "stepIn":
        case "stepOut":
            handle_action_request(msg);
            break;
        default:
            handle_request_generic(msg);
    }
}


int main(int argc, array(string) argv) {
    int port_no;

    foreach( Getopt.find_all_options( argv, ({
            ({"debug", Getopt.NO_ARG, ({"-d", "--debug"})}),
            ({"help", Getopt.NO_ARG, ({"-h", "--help"})}),
            ({"port", Getopt.MAY_HAVE_ARG, ({"-p", "--port"}), 0, DEFAULT_PORT}),
        })), [string name, mixed value]) {

        switch (name) {
            case "port":
                 port_no = (int) value;
                 im_a_server = true;
            break;
            case "debug":
                debug = true;
            break;
            case "help":
                write("\t-d --debug \t enable debug werrors.\n");
                write("\t-p --port \t communicate with debug client through\n");
                write("\t\t\t sockets. Default port is %d.\n", DEFAULT_PORT);
                write("\t\t\t If not specified, communicate through stdio.\n");
                write("\t-h --help \t print this message and exits.\n");
                exit(0);
            break;
        }
    }

    if (im_a_server) {
        DEBUG("Starting Test Debug Adapter on port %d.\n", port_no);
        Stdio.Port port = Stdio.Port(port_no);
        client = port->accept();
    } else {
        DEBUG("Starting Test Debug Adapter on stdio.\n");
        client = Stdio.File("stdin");
        obuf = Stdio.File("stdout");
    }

    client->set_nonblocking(read_cb, write_cb, close_cb);

    while (true)
        Pike.DefaultBackend(3600.0);

    return 0;
}
