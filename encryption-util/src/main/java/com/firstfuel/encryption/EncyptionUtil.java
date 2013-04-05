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
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.Set;

import org.apache.commons.lang.StringUtils;
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
    StandardPBEStringEncryptor encryptor;


    /**
     * <p>
     * </p>
     * @param args
     */
    public static void main( String[] args ) {
        System.out.println("If you want to encrypt/decrypt whole file then specify 3rd argument else dont");
        EncyptionUtil util = new EncyptionUtil();
        Response response = util.processPropertyFiles( args );
        if ( response.getExitCode() == 0 ) {
            System.out.println( response.getMessage() );
            System.exit( response.getExitCode() );
        } else if ( response.getExitCode() == 1 ) {
            System.err.println( response.getMessage() );
            System.exit( 0 );
        }
    }


    public Response processPropertyFiles( String[] args ) {
        if ( args.length < 1 ) {
            return new Response( "FirstFuel Password File is required", 0 );
        }

        if ( args.length < 2 ) {
            return new Response( "Encryption/Decryption option is required", 0 );
        }
        if ( args.length >= 2
            && !( "D".equalsIgnoreCase( args[1] ) || "E".equalsIgnoreCase( args[1] ) ) ) {
            return new Response(
                "Invalid option\n Choose either E/e for Encryption and D/d for decryption",
                0 );
        }
        boolean processFile = true;
        String inputFile = null;
        if ( args.length < 3 ) {
            processFile = false;
        } else {
            inputFile = args[2];
        }

        Properties prop = new Properties();
        try {
            // load a properties file
            prop.load( new FileInputStream( args[0] ) );

            // get the property value and print it out
            if ( prop.getProperty( "FF_SUP_PASSWORD" ) == null
                || prop.getProperty( "FF_SUP_PASSWORD" ).isEmpty() ) {
                return new Response(
                    "FF_SUP_PASSWORD property not found in the Firstfuel password file",
                    0 );
            }
            if ( prop.getProperty( "FF_SUP_ALGORITHM" ) == null
                || prop.getProperty( "FF_SUP_ALGORITHM" ).isEmpty() ) {
                return new Response(
                    "FF_SUP_ALGORITHM property not found in the Firstfuel password file",
                    0 );
            }
            encryptor = new StandardPBEStringEncryptor();
            encryptor.setPassword( prop.getProperty( "FF_SUP_PASSWORD" ) );
            encryptor.setAlgorithm( prop.getProperty( "FF_SUP_ALGORITHM" ) );
            // If a file is to be Encrypted
            if ( "E".equalsIgnoreCase( args[1] ) ) {
                if ( processFile ) {
                    encryptFile( inputFile );
                } else {
                    encryptUserInput();
                }
            }
            // If a file is to be Decrypted
            if ( "D".equalsIgnoreCase( args[1] ) ) {
                if ( processFile ) {
                    decryptFile( inputFile );
                } else {
                    decryptUserInput();
                }

            }
        } catch( IOException ex ) {
            // String message =
            // String.format("Failed to load the properties from {} to {} with exception {} ",
            // args[0],args[1],ex.getMessage());
            String message = "Failed to load the properties from " + args[0]
                + " to " + args[1] + " excepion cause :" + ex.getMessage();
            return new Response( message, 1 );
        }

        return new Response( "Sucess" );
    }


    //To Decrypt single property file   
    private void decryptUserInput() {
        System.out.println( "Utility is ready to take the string to be decrypted" );
        System.out.println( "Type the string to be decrypted. Type exit to quit" );
        BufferedReader br = new BufferedReader( new InputStreamReader(
            System.in ) );
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

    //To Encrypt single property file   
    private void encryptUserInput() {
        System.out.println( "Utility is ready to take the string to be encrypted" );
        System.out.println( "Type the string to be encrypted. Type exit to quit" );
        BufferedReader br = new BufferedReader( new InputStreamReader(
            System.in ) );
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
                    System.out.println( encrypt( data ) );
                } catch( Exception e ) {
                    System.err.println( "Failed to encrypt " + data );
                }
            } catch( IOException ioe ) {
                System.out.println( "IO error trying to read your name!" );
                System.exit( 1 );
            }
        }
    }


    /**
     * <p>
     * </p>
     * @param inputFile
     * @throws IOException
     * @throws FileNotFoundException
     * To Decrypt whole file
     */
    private void decryptFile( String inputFile )
        throws IOException, FileNotFoundException {
        File f = new File( inputFile );
        String filename = f.getName();

        Properties prop_to_encrypt = new Properties();
        prop_to_encrypt.load( new FileInputStream( inputFile ) );

        Set<Entry<Object, Object>> entries = prop_to_encrypt.entrySet();
        for( Entry<Object, Object> entry : entries ) {
            String value = (String)entry.getValue();
            String rt = StringUtils.substringAfter( value, "(" );
            String lt = StringUtils.substringBefore( rt, ")" );
            String depvalue = decrypt( lt );
            System.out.println( "Decrypted Value is =" + depvalue );
            entry.setValue( depvalue );
        }
        prop_to_encrypt.store( new FileOutputStream( "dec_" + filename ), "" );
    }


    /**
     * <p>
     * </p>
     * @param inputFile
     * To Encrypt whole file
     * @throws IOException
     * @throws FileNotFoundException
     */
    private void encryptFile( String inputFile )
        throws IOException, FileNotFoundException {
        File f = new File( inputFile );
        String filename = f.getName();
        Properties prop_to_encrypt = new Properties();
        prop_to_encrypt.load( new FileInputStream( inputFile ) );

        Set<Entry<Object, Object>> entries = prop_to_encrypt.entrySet();
        for( Entry<Object, Object> entry : entries ) {

            String value = (String)entry.getValue();
            String encvalue = encrypt( value );
          
            System.out.println( "Encrypted Value is =" + encvalue );
            entry.setValue( "ENC(" + encvalue + ")" );
        }
        // Store corresponding Encrypted values in property file
        prop_to_encrypt.store( new FileOutputStream( "enc_" + filename ), "" );
    }


    private String encrypt( String data ) {
        try {
            return encryptor.encrypt( data );
        } catch( Exception e ) {

            System.err.println( "Failed to encrypt " + data );
            e.printStackTrace();
        }
        return null;
    }

    private String decrypt( String data ) {
        try {
            return encryptor.decrypt( data );
        } catch( Exception e ) {
            System.err.println( "Failed to decrypt " + data );
            e.printStackTrace();

        }
        return null;
    }
}
