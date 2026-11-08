#!/usr/bin/env python3
"""Minimal Source RCON client. Python 3 standard library only.

Packet framing is a little-endian int32 length, int32 request id, int32 type,
a UTF-8 payload, and two trailing NUL bytes. Login is type 3. A command is
type 2. Split command responses that share a request id are concatenated.

This module was not connected to a Minecraft server on the M0 EULA stop.
"""

from __future__ import annotations

import socket
import struct
from typing import List, Tuple


TYPE_RESPONSE = 0
TYPE_COMMAND = 2
TYPE_LOGIN = 3


class RconError(RuntimeError):
    pass


def _pack(request_id: int, packet_type: int, payload: str) -> bytes:
    body = payload.encode("utf-8") + b"\x00\x00"
    header = struct.pack("<ii", request_id, packet_type)
    packet = header + body
    return struct.pack("<i", len(packet)) + packet


def _recv_exact(sock: socket.socket, size: int) -> bytes:
    chunks = []
    remaining = size
    while remaining:
        chunk = sock.recv(remaining)
        if not chunk:
            raise RconError("connection closed while reading an RCON packet")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def _read_packet(sock: socket.socket) -> Tuple[int, int, str]:
    raw_length = _recv_exact(sock, 4)
    (length,) = struct.unpack("<i", raw_length)
    if length < 10 or length > 10_000_000:
        raise RconError(f"refusing an RCON packet of length {length}")
    data = _recv_exact(sock, length)
    request_id, packet_type = struct.unpack("<ii", data[:8])
    # Drop the two trailing NUL bytes. The payload may itself contain NULs
    # only as the terminator pair Minecraft uses.
    payload = data[8:-2] if data.endswith(b"\x00\x00") else data[8:]
    text = payload.split(b"\x00", 1)[0].decode("utf-8", errors="replace")
    return request_id, packet_type, text


class RconClient:
    def __init__(self, host: str, port: int, password: str, timeout: float = 10.0) -> None:
        self.host = host
        self.port = port
        self._password = password
        self.timeout = timeout
        self._sock: socket.socket | None = None
        self._next_id = 1

    def __enter__(self) -> "RconClient":
        self.connect()
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()

    def connect(self) -> None:
        sock = socket.create_connection((self.host, self.port), self.timeout)
        sock.settimeout(self.timeout)
        self._sock = sock
        self._login()

    def close(self) -> None:
        if self._sock is not None:
            try:
                self._sock.close()
            finally:
                self._sock = None

    def _send(self, request_id: int, packet_type: int, payload: str) -> None:
        if self._sock is None:
            raise RconError("RCON socket is not connected")
        self._sock.sendall(_pack(request_id, packet_type, payload))

    def _login(self) -> None:
        request_id = self._next_id
        self._next_id += 1
        self._send(request_id, TYPE_LOGIN, self._password)
        response_id, _packet_type, _text = _read_packet(self._sock)
        if response_id == -1:
            raise RconError("RCON login failed")
        if response_id != request_id:
            raise RconError(f"RCON login returned request id {response_id}")

    def command(self, text: str) -> str:
        """Send one command and reassemble split responses for its request id."""
        if self._sock is None:
            raise RconError("RCON socket is not connected")
        request_id = self._next_id
        self._next_id += 1
        terminator_id = self._next_id
        self._next_id += 1
        self._send(request_id, TYPE_COMMAND, text)
        # A second empty command marks the end of a fragmented response.
        self._send(terminator_id, TYPE_COMMAND, "")
        parts: List[str] = []
        while True:
            response_id, packet_type, payload = _read_packet(self._sock)
            if response_id == terminator_id:
                break
            if response_id == request_id and packet_type in (TYPE_RESPONSE, TYPE_COMMAND):
                parts.append(payload)
                continue
            if response_id == request_id:
                parts.append(payload)
                continue
            raise RconError(f"unexpected RCON request id {response_id}")
        return "".join(parts)
