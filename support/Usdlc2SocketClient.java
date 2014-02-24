/* Copyright (C) 2014 paul@marrington.net, see GPL license */
import java.io.*; import java.net.*; import java.util.*;

class Usdlc2SocketClient {
  
  public static class Command {
    public void run(String[] params) {}
  }
  
  public Usdlc2SocketClient(
  String name, String host, int port, Hashtable commands) {
    this.name = name;
    this.host = host;
    this.port = port;
    this.commands = commands;
    try {
      connect();
    } catch (Exception exception) {
      System.err.println(exception.toString());
    }
  }
  public void close() { closing = true; }
  public boolean closing = false;
  public void send(String line) {
    out.println(line);
    out.flush();
  }
  public void commandProcessor() {
    String line;
    while ((line = readLine()) == null && !closing) {
      try { Thread.sleep(1000); } catch (Exception e) {}
      try { connect(); } catch (Exception e) {}
    }
    String[] params = line.split("\0");
    if ("__end__".equals(params[0])) {
      closing = true;
      try { socket.close(); } catch (Exception e) {}
      line = null;
    }
    ((Command)commands.get(params[0])).run(params);
  }
  public void startCommandProcessor() {
    (new Thread() {
        public void run() {
          while (!closing) commandProcessor();
        }
    }).start();
  }
  
  private String name, host;
  private int port;
  private Socket socket;
  private PrintWriter out;
  private BufferedReader in;
  private Hashtable commands;
  
  private void connect() throws Exception {
    socket = new Socket(host, port);
    out = new PrintWriter(socket.getOutputStream(), true);
    in = new BufferedReader(new InputStreamReader(
                            socket.getInputStream()));
    send(name);
  }
  private String readLine() {
    try { return in.readLine(); }
    catch (Exception exception) { return null; }
  }
}