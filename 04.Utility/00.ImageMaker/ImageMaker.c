/**
 *  file    ImageMaker.c
 *  date    2008/12/16
 *  author  kkamagui 
 *          Copyright(c)2008 All rights reserved by kkamagui
 *  brief   ��Ʈ �δ��� Ŀ�� �̹����� �����ϰ�, ���� ������ ������ �ִ� ImageMaker�� 
 *          �ҽ� ����
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#ifndef O_BINARY
#define O_BINARY 0x00
#endif

#define BYTESOFSECTOR  512

// �Լ� ����
int AdjustInSectorSize( int iFd, int iSourceSize );
void WriteKernelInformation( int iTargetFd, int iKernelSectorCount );
int CopyFile( int iSourceFd, int iTargetFd );

/**
 *  Main �Լ�
*/
int main(int argc, char* argv[])
{
    int iSourceFd;
    int iTargetFd;
    int iTempFd;
    int iBootLoaderSize;
    int iKernel32SectorCount;
    int iSourceSize;
        
    // Ŀ�ǵ� ���� �ɼ� �˻�
    if( argc < 3 )
    {
        fprintf( stderr, "[ERROR] ImageMaker.out BootLoader.bin Kernel32.bin\n" );
        exit( -1 );
    }
    
    // Disk.img ������ ����
    if( ( iTargetFd = open( "Disk.img", O_RDWR | O_CREAT |  O_TRUNC |
            O_BINARY , S_IREAD | S_IWRITE) ) == -1 )
    {
        fprintf( stderr , "[ERROR] Disk.img open fail.\n" );
        exit( -1 );
    }

    //--------------------------------------------------------------------------
    // ��Ʈ �δ� ������ ��� ��� ������ ��ũ �̹��� ���Ϸ� ����
    //--------------------------------------------------------------------------
    printf( "[INFO] Copy boot loader to image file\n" );
    if( ( iSourceFd = open( argv[ 1 ], O_RDONLY | O_BINARY ) ) == -1 )
    {
        fprintf( stderr, "[ERROR] %s open fail\n", argv[ 1 ] );
        exit( -1 );
    }

    iSourceSize = CopyFile( iSourceFd, iTargetFd );
    close( iSourceFd );
    
    // ���� ũ�⸦ ���� ũ���� 512����Ʈ�� ���߱� ���� ������ �κ��� 0x00 ���� ä��
    iBootLoaderSize = AdjustInSectorSize( iTargetFd , iSourceSize );
    printf( "[INFO] %s size = [%d] and sector count = [%d]\n",
            argv[ 1 ], iSourceSize, iBootLoaderSize );
    
    // Get hash value
    if( ( iSourceFd = open( argv[ 2 ], O_RDONLY | O_BINARY ) ) == -1 )
    {
        fprintf( stderr, "[ERROR] %s open fail\n", argv[ 2 ] );
        exit( -1 );
    }
    unsigned char hash[4];
    unsigned char temp[4];
    ssize_t rd_size;

    read(iSourceFd, hash, 4);
    /*
    printf("hash : ");
    for (int i = 0; i < 4; i++) {
        printf("%02x", hash[i]);
    }
    */
    while(0 < (rd_size = read(iSourceFd, temp, 4))) {
        for (int i = 0; i < 4; i++) {
            hash[i] = (hash[i] ^ temp[i]);
        }
        /*
        printf("    temp : ");
        for (int i = 0; i < 4; i++) {
            printf("%02x", temp[i]);
        }
        printf("\nhash : ");
        for (int i = 0; i < 4; i++) {
            printf("%02x", hash[i]);
        }
        */
    }
    //printf("\n");
    close(iSourceFd);

    for (int i = 0; i < 4; i++) {
        printf("%02x", hash[i]);
    }
    printf("\n");
 
    // Copy Kernel32.bin to temp.bin
    if( ( iTempFd = open( "Temp.bin", O_RDWR | O_CREAT |  O_TRUNC |
            O_BINARY , S_IREAD | S_IWRITE) ) == -1 )
    {
        fprintf( stderr, "[ERROR] Temp.bin open fail\n");
        exit( -1 );
    }
    if ((iSourceFd = open(argv[2], O_RDONLY | O_BINARY)) == -1) {
        fprintf( stderr, "[ERROR] %s open fail\n", argv[ 2 ] );
        exit( -1 );
    }

    iSourceSize = CopyFile(iSourceFd, iTempFd);
    close(iTempFd);
    close(iSourceFd);

    if ((iTempFd = open("Temp.bin", O_RDONLY | O_BINARY)) == -1) {
        fprintf( stderr, "[ERROR] Temp.bin open fail\n");
        exit( -1 );
    }
    if ((iSourceFd = open(argv[2], O_WRONLY | O_BINARY | O_TRUNC)) == -1) {
        fprintf( stderr, "[ERROR] %s open fail\n", argv[ 2 ] );
        exit( -1 );
    }
    write(iSourceFd, hash, 4);
    iSourceSize = CopyFile(iTempFd, iSourceFd);
    close(iTempFd);
    close(iSourceFd);
  
    // Remove temp.bin
    if (remove("Temp.bin") == 0){
        printf("Delete temp.bin Success\n");
    }
    else {
        printf("Delete temp.bin failed\n");
    }

    //--------------------------------------------------------------------------
    // 32��Ʈ Ŀ�� ������ ��� ��� ������ ��ũ �̹��� ���Ϸ� ����
    //--------------------------------------------------------------------------
    printf( "[INFO] Copy protected mode kernel to image file\n" );
    if( ( iSourceFd = open( argv[ 2 ], O_RDONLY | O_BINARY ) ) == -1 )
    {
        fprintf( stderr, "[ERROR] %s open fail\n", argv[ 2 ] );
        exit( -1 );
    }

    iSourceSize = CopyFile( iSourceFd, iTargetFd );
    close( iSourceFd );
    
    // ���� ũ�⸦ ���� ũ���� 512����Ʈ�� ���߱� ���� ������ �κ��� 0x00 ���� ä��
    iKernel32SectorCount = AdjustInSectorSize( iTargetFd, iSourceSize );
    printf( "[INFO] %s size = [%d] and sector count = [%d]\n",
                argv[ 2 ], iSourceSize, iKernel32SectorCount );

    //--------------------------------------------------------------------------
    // ��ũ �̹����� Ŀ�� ������ ����
    //--------------------------------------------------------------------------
    printf( "[INFO] Start to write kernel information\n" );    
    // ��Ʈ������ 5��° ����Ʈ���� Ŀ�ο� ���� ������ ����
    WriteKernelInformation( iTargetFd, iKernel32SectorCount );
    printf( "[INFO] Image file create complete\n" );

    close( iTargetFd );
    return 0;
}

/**
 *  ���� ��ġ���� 512����Ʈ ��� ��ġ���� ���߾� 0x00���� ä��
*/
int AdjustInSectorSize( int iFd, int iSourceSize )
{
    int i;
    int iAdjustSizeToSector;
    char cCh;
    int iSectorCount;

    iAdjustSizeToSector = iSourceSize % BYTESOFSECTOR;
    cCh = 0x00;
    
    if( iAdjustSizeToSector != 0 )
    {
        iAdjustSizeToSector = 512 - iAdjustSizeToSector;
        printf( "[INFO] File size [%lu] and fill [%u] byte\n", iSourceSize, 
            iAdjustSizeToSector );
        for( i = 0 ; i < iAdjustSizeToSector ; i++ )
        {
            write( iFd , &cCh , 1 );
        }
    }
    else
    {
        printf( "[INFO] File size is aligned 512 byte\n" );
    }
    
    // ���� ���� �ǵ�����
    iSectorCount = ( iSourceSize + iAdjustSizeToSector ) / BYTESOFSECTOR;
    return iSectorCount;
}

/**
 *  ��Ʈ �δ��� Ŀ�ο� ���� ������ ����
*/
void WriteKernelInformation( int iTargetFd, int iKernelSectorCount )
{
    unsigned short usData;
    long lPosition;
    
    // ������ ���ۿ��� 5����Ʈ ������ ��ġ�� Ŀ���� �� ���� �� ������ ��Ÿ��
    lPosition = lseek( iTargetFd, 5, SEEK_SET );
    if( lPosition == -1 )
    {
        fprintf( stderr, "lseek fail. Return value = %d, errno = %d, %d\n", 
            lPosition, errno, SEEK_SET );
        exit( -1 );
    }


    usData = ( unsigned short ) iKernelSectorCount;

    write( iTargetFd, &usData, 2 );

    printf( "[INFO] Total sector count except boot loader [%d]\n", 
        iKernelSectorCount );
}

/**
 *  �ҽ� ����(Source FD)�� ������ ��ǥ ����(Target FD)�� �����ϰ� �� ũ�⸦ �ǵ�����
*/
int CopyFile( int iSourceFd, int iTargetFd )
{
    int iSourceFileSize;
    int iRead;
    int iWrite;
    char vcBuffer[ BYTESOFSECTOR ];

    iSourceFileSize = 0;
    while( 1 )
    {
        iRead   = read( iSourceFd, vcBuffer, sizeof( vcBuffer ) );
        iWrite  = write( iTargetFd, vcBuffer, iRead );

        if( iRead != iWrite )
        {
            fprintf( stderr, "[ERROR] iRead != iWrite.. \n" );
            exit(-1);
        }
        iSourceFileSize += iRead;
        
        if( iRead != sizeof( vcBuffer ) )
        {
            break;
        }
    }
    return iSourceFileSize;
} 