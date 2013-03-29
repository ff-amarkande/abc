/**
 * EncyptionUtil.java
 * 29-Mar-2013
 * <p>
 * Copyright © FirstFuel Software. 2010-2013 All right reserved. The copyright
 * to the computer program(s) herein is the property of FirstFuel Software. The
 * program(s) may be used and/or copied only with the written permission of
 * FirstFuel Software.
 * </p>
 */
package com.firstfuel.encryption;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Properties;

import org.jasypt.encryption.pbe.StandardPBEStringEncryptor;

/**
 * <p>
 * EncyptionUtil
 * </p>
 * @version 1.0
 * @author Ameeth Paatil
 * @since 29-Mar-2013
 */
public class EncyptionUtil {

    /**
     * <p>
     * </p>
     * @param args
     */
    public static void main( String[] args ) {
        if ( args.length < 1 ) {
            System.out.println( "FirstFuel Password File is required" );
            System.exit( 0 );
        }
        Properties prop = new Properties();
        try {
            // load a properties file
            prop.load( new FileInputStream( args[0] ) );
            // get the property value and print it out
            if ( prop.getProperty( "FF_SUP_PASSWORD" ) == null || prop.getProperty( "FF_SUP_PASSWORD" ).isEmpty() ) {
                System.out.println( "FF_SUP_PASSWORD property not found in the Firstfuel password file" );
                System.exit( 0 );
            }
            if ( prop.getProperty( "FF_SUP_ALGORITHM" ) == null || prop.getProperty( "FF_SUP_ALGORITHM" ).isEmpty() ) {
                System.out.println( "FF_SUP_ALGORITHM property not found in the Firstfuel password file" );
                System.exit( 0 );
            }
            EncyptionUtil util = new EncyptionUtil();
            if ( args.length > 1 && "D".equalsIgnoreCase( args[1] ) ) {
                util.decrypt( prop );
            } else {
                util.encrypt( prop );
            }
        } catch( IOException ex ) {
            System.err.println( "Failed to load the properties from " + args[0] );
        }
    }

    private void encrypt( Properties prop ) {
        StandardPBEStringEncryptor encryptor = new StandardPBEStringEncryptor();
        encryptor.setPassword( prop.getProperty( "FF_SUP_PASSWORD" ) );
        encryptor.setAlgorithm( prop.getProperty( "FF_SUP_ALGORITHM" ) );
        System.out.println( "Utility is ready to take the string to be encrypted" );
        System.out.println( "Type the string to be encrypted. Type exit to quit" );
        BufferedReader br = new BufferedReader( new InputStreamReader( System.in ) );
        String data = null;
        while ( true ) {
            try {
                System.out.print( ">" );
                data = br.readLine();
                if ( "exit".equalsIgnoreCase( data ) ) {
                    System.out.println( "Bye!!!!" );
                    System.exit( 0 );
                }
                try {
                    System.out.println( encryptor.encrypt( data ) );
                } catch( Exception e ) {
                    System.err.println( "Failed to encrypt " + data );
                }
            } catch( IOException ioe ) {
                System.out.println( "IO error trying to read your name!" );
                System.exit( 1 );
            }
        }
    }

    private void decrypt( Properties prop ) {
        StandardPBEStringEncryptor encryptor = new StandardPBEStringEncryptor();
        encryptor.setPassword( prop.getProperty( "FF_SUP_PASSWORD" ) );
        encryptor.setAlgorithm( prop.getProperty( "FF_SUP_ALGORITHM" ) );
        System.out.println( "Utility is ready to take the string to be decrypted" );
        System.out.println( "Type the string to be decrypted. Type exit to quit" );
        BufferedReader br = new BufferedReader( new InputStreamReader( System.in ) );
        String data = null;
        while ( true ) {
            try {
                System.out.print( ">" );
                data = br.readLine();
                if ( "exit".equalsIgnoreCase( data ) ) {
                    System.out.println( "Bye!!!!" );
                    System.exit( 0 );
                }
                try {
                    System.out.println( encryptor.decrypt( data ) );
                } catch( Exception e ) {
                    System.err.println( "Failed to decrypt " + data );
                }
            } catch( IOException ioe ) {
                System.out.println( "IO error trying to read your name!" );
                System.exit( 1 );
            }
        }

    }
}
