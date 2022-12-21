function cst_open_manual()
%find the location of the asmita app and open the manual
appinfo = matlab.apputil.getInstalledAppInfo;
idx = find(strcmp({appinfo.name},'CSTmodel'));
fpath = [appinfo(idx(1)).location,[filesep,'doc',filesep,'CSTmodel manual.pdf']];
open(fpath)
