# Nginx on Unikraft

To build and run this application please use the `kraft` script:

    pip3 install git+https://github.com/unikraft/kraft.git
    mkdir my-nginx && cd my-nginx
    kraft up -p PLATFORM -m ARCHITECTURE -a nginx my-nginx

For more information about `kraft` type ```kraft -h``` or read the
[documentation](http://docs.unikraft.org).
