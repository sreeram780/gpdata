//
//  ViewController.m
//  gpdata
//
//  Created by sreenivasulareddy on 04/11/15.
//  Copyright © 2015 sreenivasulareddy. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,NSURLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate>
{
    NSURLSessionDownloadTask *download;
    NSString *pdfDocumentfileName;
}
@property (nonatomic, strong)NSURLSession *backgroundSession;


@property (nonatomic,retain) NSMutableArray *presentations;
@property (nonatomic,retain) NSMutableArray *presentcopy,*sessionName;
@property (nonatomic,retain) NSMutableDictionary *sections;
@property (strong, nonatomic) IBOutlet UITableView *Stableview;

@end

@implementation ViewController
- (void)showFile:(NSString*)path{
    
    // Check if the file exists
    BOOL isFound = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (isFound) {
        
        UIDocumentInteractionController *viewer = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
        viewer.delegate = self;
        [viewer presentPreviewAnimated:YES];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.sections = [[NSMutableDictionary alloc] init];
    
    
    NSURLSessionConfiguration *backgroundConfigurationObject = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"myBackgroundSessionIdentifier"];
    self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfigurationObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];

    
    NSURL *url = [NSURL URLWithString:@"http://67.220.115.29:8080/vconforence-1/rest/sessionPresentations?eventDBKey=1"];
    
       NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{ };
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *dataTask =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
     {
         NSMutableArray *jsonArry = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
         self.presentcopy = [[NSMutableArray alloc]init];
         self.sessionName = [[NSMutableArray alloc]init];

         for (int i =0; i<jsonArry.count; i++) {
             [self.presentcopy addObjectsFromArray:[jsonArry[i]objectForKey:@"presentations"]];
             if ([[jsonArry[i]objectForKey:@"presentations"] count]>0) {
                 [self.sessionName addObject:[jsonArry[i]objectForKey:@"agendaName"]];

             }
             
         }
         [self initialiseArray:self.presentcopy];
         [self.Stableview reloadData];                                         }
     
     ];
    
    [dataTask resume];
}

-(void)initialiseArray:(NSMutableArray*)array{
    
   self.presentations = [NSMutableArray arrayWithArray:array];

    BOOL found;
    
    // Loop through the books and create our keys
        for (NSDictionary *book in self.presentations)
        {
        
        NSString *c = [book objectForKey:@"agendaName"] ;
        
        found = NO;
        
        for (NSString *str in [self.sections allKeys])
        {
            if ([str isEqualToString:c])
            {
                found = YES;
            }
        }
        
        if (!found)
        {
            [self.sections setValue:[[NSMutableArray alloc] init] forKey:c];
        }
        
    }
    
    // Loop again and sort the books into their respective keys
    for (NSDictionary *book in self.presentations)
    {
        
         [[self.sections objectForKey:[book objectForKey:@"agendaName"]] addObject:book];
    }
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return [[self comparetheArray:(NSMutableArray*)[self.sections allKeys]] count];
    
}
-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    
    header.contentView.backgroundColor = [UIColor blueColor];
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1.0f;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
         NSLog(@"Section title  is %@",[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]);
    
 
    return [[self comparetheArray:(NSMutableArray*)[self.sections allKeys]]objectAtIndex:section];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
       return [[self.sections valueForKey:[[self comparetheArray:(NSMutableArray*)[self.sections allKeys]]objectAtIndex:section]] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] ;
    }
    
  
    NSDictionary *book = [[self.sections valueForKey:[[self comparetheArray:(NSMutableArray*)[self.sections allKeys]]objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [book objectForKey:@"presentationName"];
    cell.detailTextLabel.text =[[book objectForKey:@"presentationFileMimeType"] isEqualToString:@"PDF"]?@"PDF FILE":@"VIDEO";
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSDictionary *book = [[self.sections valueForKey:[[self comparetheArray:(NSMutableArray*)[self.sections allKeys]]objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
    if ([cell.detailTextLabel.text isEqualToString:@"PDF FILE"]) {
        if (nil == download){
            pdfDocumentfileName=[NSMutableString stringWithFormat:@"%@.pdf",cell.textLabel.text];
            NSMutableString *urlStr=[NSMutableString stringWithFormat:@"%@",[book objectForKey:@"presentationFile"]];
            NSString* encodedUrl = [urlStr stringByAddingPercentEscapesUsingEncoding:
                                    NSUTF8StringEncoding];
            NSURL *url = [NSURL URLWithString:encodedUrl];
            
            download = [self.backgroundSession downloadTaskWithURL:url];
            [download resume];
        }
    }

}


-(NSMutableArray*)comparetheArray:(NSMutableArray*)arra{
    NSMutableArray *orederArr = [[NSMutableArray alloc]init];
    NSMutableArray *inorederArr = [NSMutableArray arrayWithArray:arra];
        for (NSString *str in self.sessionName) {
            for (NSString *str1 in inorederArr) {
                if ([str isEqualToString:str1]) {
                    [orederArr addObject:str];
                }
        }
    }
    return orederArr;
}
#pragma mark - NSURLSessionDownloadDelegate protocol

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    // This delegate method provides the app with the URL to a temporary file where the downloaded content is stored.
    NSLog(@"Session %@ download task %@ finished downloading to URL %@\n",
          session, downloadTask, location);
    
    // Get the path for the document directory, because we will move the temporary file to that directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectoryPath = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Create the destination path
    NSURL *destinationURL = [NSURL fileURLWithPath:[documentDirectoryPath stringByAppendingPathComponent:pdfDocumentfileName]];
    
    NSError *error = nil;
    
    // If file path already exist, replace it with the file you just downloaded
    if ([fileManager fileExistsAtPath:[destinationURL path]]){
        [fileManager replaceItemAtURL:destinationURL withItemAtURL:destinationURL backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:nil error:&error];
        [self showFile:[destinationURL path]];
        
    }else{
        // Move the file to a permanent location
        if ([fileManager moveItemAtURL:location toURL:destinationURL error:&error]) {
            
            [self showFile:[destinationURL path]];
        }else{
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"PDFDownloader" message:[NSString stringWithFormat:@"An error has occurred when moving the file: %@",[error localizedDescription]] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    // This delegate method provides the app with status informations about the progress of the download
    NSLog(@"downloaded: %qi",totalBytesWritten);
    
    //    [self.progressView setProgress:(double)totalBytesWritten/(double)totalBytesExpectedToWrite
    //                          animated:YES];
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
    // This delegate method is called when its attempt to resume a previously failed download was successful
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"PDFDownloader" message:@"Download is resumed successfully" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}


#pragma mark - NSURLSessionTaskDelegate protocol

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    download = nil;
    //    [self.progressView setProgress:0];
    
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"PDFDownloader" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *) documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller{
    
    return self;
}
-(void)moviePlayBackDidFinish:(NSNotificationCenter*)nscenter{
    
    
}

@end
