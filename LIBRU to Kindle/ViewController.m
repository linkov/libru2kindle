//
//  ViewController.m
//  LIBRU to Kindle
//
//  Created by alex on 12/27/14.
//  Copyright (c) 2014 SDWR. All rights reserved.
//
@import WebKit;
#import "ViewController.h"

@interface ViewController () <WKNavigationDelegate>
@property (strong) WKWebView *webView;
@property (strong) NSString *path;
@property (strong) IBOutlet NSTextField *bookURL;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSTaskDidTerminateNotification object:nil queue:nil usingBlock:^(NSNotification *note) {

        NSURL *fileURL = [NSURL fileURLWithPath:self.path];
        NSURL *folderURL = [fileURL URLByDeletingLastPathComponent];
        [[NSWorkspace sharedWorkspace] openURL: folderURL];

    }];

}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {

    NSString *jsToGetHTMLSource = @"document.documentElement.outerHTML";
    [self.webView evaluateJavaScript:jsToGetHTMLSource completionHandler:^(NSString *obj, NSError *err) {

        if (err) {
            NSLog(@"js error - %@",err);
            return;
        }

        NSError* saveError = nil;

        NSString *UTF8Str = obj;

        [UTF8Str writeToFile:self.path atomically:YES encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKOI8_R) error:&saveError];


        if (saveError) {
            NSLog(@"save error - %@",saveError);
            return;
        }

        [self convertToMobyAtPath:self.path];


    }];

}

- (NSString *)goodURL:(NSURL *)url {

    return [url.absoluteString stringByReplacingOccurrencesOfString:@"file:///" withString:@""];
}

- (void)convertToMobyAtPath:(NSString *)path {

    NSURL* url = [[NSBundle mainBundle] URLForResource:@"kindlegen" withExtension:@""];
    NSString *fString = [url.absoluteString stringByReplacingOccurrencesOfString:@"file:///" withString:@""];
    NSString *fcommand = [NSString stringWithFormat:@"/%@ %@ -verbose",fString,path];
    NSLog(@"%@",fcommand);
    NSString *commandRes = runCommand(fcommand);

    NSLog(@"commandRes: %@",commandRes);
}


- (IBAction)generateBook:(id)sender {

    NSString *fileName = [[[self.bookURL.stringValue lastPathComponent] stringByReplacingOccurrencesOfString:@".txt" withString:@""] stringByAppendingString:@".html"];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savePath = [documentsDirectory stringByAppendingPathComponent:fileName];

    self.path = savePath;


    NSString *script =[NSString stringWithFormat:
    @"document.querySelector('form').remove();"
    "document.querySelector('pre > div').remove();"

    "var meta = document.createElement('meta');"
    "meta.setAttribute('http-equiv', 'content-type');"
    "meta.setAttribute('content', 'text/html; charset=KOI8-R');"
    "document.getElementsByTagName('head')[0].appendChild(meta);"

    "var nav = document.createElement('nav');"
    "nav.setAttribute('epub:type', 'toc');"

    "var ulElement = document.createElement('ol');"
    "var allH2 = document.getElementsByTagName('ul');"
    "var inputList = Array.prototype.slice.call(allH2);"
    "inputList.splice(0, 1);"
    "inputList.forEach(function(element, index, array) {"
    "var ent = element.cloneNode(true);"
    "var liElement = document.createElement('li');"
    "var aElement = document.createElement('a');"
    "aElement.href='%@#'+ent.querySelector('a').name;"

    "var h1Element = document.createElement('h1');"
    "var t = document.createTextNode(ent.querySelector('h2').innerHTML);"
    "h1Element.appendChild(t);"

    "aElement.innerHTML =  ent.querySelector('h2').innerHTML;"
    "liElement.appendChild(aElement);"
    "ulElement.appendChild(liElement);"
    "});"
    "nav.appendChild(ulElement);"
    "document.body.insertBefore(nav, document.body.childNodes[0]);"

    ,fileName];


    WKUserScript *userScr = [[WKUserScript alloc]initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *controller = [[WKUserContentController alloc]init];
    [controller addUserScript:userScr];

    WKWebViewConfiguration *conf = [[WKWebViewConfiguration alloc]init];
    conf.userContentController = controller;

    self.webView = [[WKWebView alloc]initWithFrame:self.view.bounds configuration:conf];
    self.webView.navigationDelegate = self;

    NSURL *authURL = [NSURL URLWithString:self.bookURL.stringValue];
    NSURLRequest *request = [NSURLRequest requestWithURL:authURL];
    [self.webView loadRequest:request];

}

#pragma mark - Utils


NSString *runCommand(NSString *commandToRun)
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];



    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@", commandToRun],
                          nil];
    NSLog(@"run command: %@",commandToRun);
    [task setArguments: arguments];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file;
    file = [pipe fileHandleForReading];

    [task launch];

    NSData *data;
    data = [file readDataToEndOfFile];

    NSString *output;
    output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

@end
