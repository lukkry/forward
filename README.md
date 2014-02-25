# Forward

The ruby client for [https://forwardhq.com/](https://forwardhq.com/). Forward gives you a sharable URL for localhost websites/webapps.

## Usage

    > forward <port> [options]
    > forward <host> [options]
    > forward <host:port> [options]

    Description:

       Share a server running on localhost:port over the web by tunneling
       through Forward. A URL is created for each tunnel.

    Simple example:

      # You are developing a Rails site.

      > rails server &
      > forward 3000
        Forward created at https://mycompany.fwd.wf

    Assigning a static subdomain prefix:

      > rails server &
      > forward 3000 myapp
        Forward created at https://myapp-mycompany.fwd.wf

    Virtual Host example:

      # You are already running something on port 80 that uses
      # virtual host names.

      > forward mysite.dev
        Forward created at https://mycompany.fwd.wf