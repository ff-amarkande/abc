package com.firstfuel.encryption;

public class Response {
    
    private String message ;
    
    private int exitCode = -999;

    public String getMessage() {
        return message;
    }

    public int getExitCode() {
        return exitCode;
    }

    public Response( String message, int exitCode ) {
        super();
        this.message = message;
        this.exitCode = exitCode;
    }

    public Response( String message ) {
        super();
        this.message = message;
    }

    
    
    
}
