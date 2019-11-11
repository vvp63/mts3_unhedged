unit linuxclib;

interface

uses  baseunix, linux, sockets;

const clib = 'c';

function cl_socket(domain: cint; _type: cint; protocol: cint): cint; cdecl;
function cl_bind(fd: cint; addr: psockaddr; len: tsocklen):cint; cdecl;
function cl_connect(fd: cint; addr: psockaddr; len: tsocklen):cint; cdecl;
function cl_setsockopt(fd: cint; level: cint; optname: cint; optval: pointer; optlen: tsocklen): cint; cdecl; 
function cl_shutdown(fd: cint; how: cint): cint; cdecl;

function cl_select(nfds: cint; readfds: pfdset; writefds: pfdset; exceptfds: pfdset; timeout: cint): cint; cdecl;

function cl_ioctl(fd: cint; request: TIOCtlRequest; args:pointer): cint; cdecl;

function cl_readv(fd: cint; vector: piovec; count: cint): ssize_t; cdecl;
function cl_writev(fd: cint; vector: piovec; count: cint): ssize_t; cdecl;

function cl_recv(fd: cint; buf: pointer; len: size_t; flags:cint): ssize_t; cdecl;
function cl_send(fd: cint; buf: pointer; len: size_t; flags:cint): ssize_t; cdecl;

function cl_closesocket(fd: cint): cint; cdecl;
function cl_close(fd: cint): cint; cdecl;

function cl_poll(fds: Ppollfd; nfds: cuint; timeout: clong): cint; cdecl;

function cl_epoll_create(size: cint): cint; cdecl;
function cl_epoll_ctl(epfd, op, fd: cint; event: pepoll_event): cint; cdecl;
function cl_epoll_wait(epfd: cint; events: pepoll_event; maxevents, timeout: cint): cint; cdecl;

function cl_gettimeofday(tp: pointer; tzp: pointer): cint; cdecl;
function cl_clock_gettime(clk_id: cint; tp: pointer): cint; cdecl;

implementation

function cl_socket; external clib name 'socket';
function cl_bind; external clib name 'bind';
function cl_connect; external clib name 'connect';
function cl_setsockopt; external clib name 'setsockopt';
function cl_shutdown; external clib name 'shutdown';

function cl_select; external clib name 'select';

function cl_ioctl; external clib name 'ioctl';

function cl_readv; external clib name 'readv';
function cl_writev; external clib name 'writev';

function cl_recv; external clib name 'recv';
function cl_send; external clib name 'send';

function cl_closesocket; external clib name 'close';
function cl_close; external clib name 'close';

function cl_poll; external clib name 'poll';

function cl_epoll_create; external clib name 'epoll_create';
function cl_epoll_ctl; external clib name 'epoll_ctl';
function cl_epoll_wait; cdecl; external clib name 'epoll_wait';

function cl_gettimeofday; cdecl; external clib name 'gettimeofday';
function cl_clock_gettime; cdecl; external clib name 'clock_gettime';

end.