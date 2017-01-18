# -*- coding: utf-8 -*-
# Copyright (C) Mesosphere, Inc. See LICENSE file for details.

"""All the code relevant to recording endpoint used by mocker.
"""

import copy
import logging
import time

from mocker.endpoints.generic import (
    TcpIpHttpEndpoint,
)
from mocker.endpoints.basehandler import (
    BaseHTTPRequestHandler,
)

# pylint: disable=C0103
log = logging.getLogger(__name__)


# pylint: disable=R0903
class RecordingHTTPRequestHandler(BaseHTTPRequestHandler):
    """A request hander class implementing recording all the requests&request
    data made to given endpoint.

    This class will most likely be inherited from and extended with some
    extra code that actually processes the requests because on itself
    it just returns some sample text.
    """
    def _calculate_response(self, *_):
        """This method does not really do any useful work, it is here only to
        satisfy the interface.

        As mentioned in the class description, it most probably will be
        overridden in inheriting classes. Because of that all input arguments
        are ignored.

        Please refer to the description of the BaseHTTPRequestHandler class
        for details on the arguments and return value of this method.
        """
        res = {"msg": 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'}
        blob = self._convert_data_to_blob(res)

        return blob

    def _record_request(self):
        """Store all the relevant data of the request into the endpoint context."""
        ctx = self.server.context

        res = {}
        res['method'] = self.command
        res['path'] = self.path
        res['headers'] = self.headers.items()
        res['request_version'] = self.request_version
        if self.headers.get('Content-Length') is not None:
            body_length = int(self.headers.get('Content-Length'))
            res['request_body'] = self.rfile.read(body_length).decode('utf-8')
        else:
            res['request_body'] = None
        res['request_time'] = time.time()

        with ctx.lock:
            ctx.data['requests'].append(res)
        msg_fmt = "Endpoint `%s` recorded a request: `%s`"
        log.debug(msg_fmt, ctx.data['endpoint_id'], res)

    def _send_response(self, blob):
        """Send response to the client.

        The method handles:
          * sending broken response if tests requested it
          * recording the request data if enabled
          * sending the default/good response in all other cases.

        Please refer to the description of the BaseHTTPRequestHandler class
        for details on the arguments of this method.
        """
        ctx = self.server.context
        with ctx.lock:
            # Seems a bit overkill:
            do_record_request = ctx.data["record_requests"]
            do_always_bork = ctx.data['always_bork']
            do_always_redirect = ctx.data['always_redirect']
            redirect_target = ctx.data['redirect_target']

        if do_record_request:
            self._record_request()

        if do_always_bork:
            msg_fmt = "Endpoint `%s` sending broken response as requested"
            log.debug(msg_fmt, ctx.data['endpoint_id'])
            blob = b"Broken response due to `always_bork` flag being set"
            self._finalize_request(500, 'text/plain; charset=utf-8', blob)
            return

        if do_always_redirect:
            msg_fmt = "Endpoint `%s` sending redirect to `%s` as requested"
            log.debug(msg_fmt, ctx.data['endpoint_id'], redirect_target)
            headers = {"Location": redirect_target}
            self._finalize_request(307,
                                   'text/plain; charset=utf-8',
                                   blob,
                                   extra_headers=headers)
            return

        self._finalize_request(200, 'application/json', blob)

    @staticmethod
    def _parse_request_body():
        """Unused, just to satisfy the interface"""
        return None


# pylint: disable=C0103
class RecordingTcpIpEndpoint(TcpIpHttpEndpoint):
    """An endpoint that will record all the requests made to it.

    This endpoint can be used to test features that work in the background
    and are unavailable directly from the HTTP client context.

    In its current form, its functionality is incomplete/serves only some
    example data, it has to be extended/inherited from in order to serve as a
    mock.
    """
    def __init__(self, port, ip='', request_handler=RecordingHTTPRequestHandler):
        """Initialize new RecordingTcpIpEndpoint endpoint"""
        super().__init__(request_handler, port, ip)
        self._context.data["record_requests"] = False
        self._context.data["requests"] = list()

    def record_requests(self, *_):
        """Enable recording the requests data by the handler."""
        with self._context.lock:
            self._context.data["record_requests"] = True

    def get_recorded_requests(self, *_):
        """Fetch all the recorded requests data from the handler"""
        with self._context.lock:
            requests_list_copy = copy.deepcopy(self._context.data["requests"])

        return requests_list_copy

    def reset(self, *_):
        """Reset the endpoint to the default/initial state."""
        with self._context.lock:
            super().reset()
            self._context.data["record_requests"] = False
            self._context.data["requests"] = list()
