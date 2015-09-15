# hearhere

*Hearhere* is a user-centric radio application that allows multiple users to input short segments of sound to an FM station live from their browsers (on desktop or mobile).  It is an experiment in building a democratic and reactive electronic *space* where users can connect direct live audio from disperate remote locations to a central FM broadcast.

*Hearhere* uses new web technologies like WebRTC, WebAudioApi, and websockets to connect users into one radiophonic event.  The system consists of a single  server-in-a-webpage (master.html) and multiple clients (index.html). The signalling portion of the WebRTC compenent currently runs over socket.io and is managaed by server.coffee.  

Recent desktop Firefox and Chrome browsers work splendidly.   On mobile, recent android webview (their default), chrome and firefox all function as expected/needed.  Nothing currently works on iphone unfortunately. 

The development of *hearhere* has been generously sponsored by https://wavefarm.org/


<img src="https://wavefarm.org/images/wf-logo.png" align="left" height="100" width="100" >

