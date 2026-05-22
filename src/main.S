.intel_syntax noprefix

# x64 Windows cache cleaner prototype.
# The clean path is deliberately conservative: it only deletes children under
# low-risk target roots, keeps the target root, and skips reparse points.

.equ NULL, 0
.equ TRUE, 1
.equ FALSE, 0

.equ WM_CREATE, 1
.equ WM_DESTROY, 2
.equ WM_SIZE, 5
.equ WM_COMMAND, 273
.equ WM_SCAN_DONE, 0x8001
.equ WM_PROGRESS, 0x8002

.equ WS_OVERLAPPEDWINDOW, 0x00cf0000
.equ WS_CHILD, 0x40000000
.equ WS_VISIBLE, 0x10000000
.equ WS_BORDER, 0x00800000
.equ WS_VSCROLL, 0x00200000
.equ WS_HSCROLL, 0x00100000
.equ ES_MULTILINE, 0x0004
.equ ES_AUTOVSCROLL, 0x0040
.equ ES_AUTOHSCROLL, 0x0080
.equ ES_READONLY, 0x0800
.equ BS_PUSHBUTTON, 0x00000000
.equ BS_AUTOCHECKBOX, 0x00000003
.equ CW_USEDEFAULT, 0x80000000
.equ SW_SHOWDEFAULT, 10
.equ IDC_ARROW, 32512
.equ COLOR_WINDOW_BRUSH, 6
.equ INVALID_FILE_ATTRIBUTES, 0xffffffff

.equ ID_SCAN, 1001
.equ ID_DRYRUN, 1002
.equ ID_STOP, 1003
.equ ID_CLEAN, 1004
.equ LOG_LIMIT, 65500

.extern RegisterClassExW
.extern CreateWindowExW
.extern DefWindowProcW
.extern ShowWindow
.extern UpdateWindow
.extern GetMessageW
.extern TranslateMessage
.extern DispatchMessageW
.extern PostQuitMessage
.extern LoadCursorW
.extern MoveWindow
.extern SetWindowTextW
.extern ExpandEnvironmentStringsW
.extern GetFileAttributesW
.extern FindFirstFileW
.extern FindNextFileW
.extern FindClose
.extern CreateThread
.extern CloseHandle
.extern WaitForSingleObject
.extern PostMessageW
.extern EnableWindow
.extern MessageBoxW
.extern DeleteFileW
.extern RemoveDirectoryW
.extern MultiByteToWideChar
.extern WideCharToMultiByte
.extern CreateFontW
.extern DeleteObject
.extern SendMessageW
.extern GetModuleFileNameW
.extern GetLocalTime
.extern CreateFileW
.extern WriteFile
.extern FlushFileBuffers
.extern GetModuleHandleW
.extern ExitProcess

.equ CP_UTF8, 65001
.equ WM_SETFONT, 48
.equ BM_GETCHECK, 240
.equ BM_SETCHECK, 241
.equ BST_CHECKED, 1
.equ FW_NORMAL, 400
.equ DEFAULT_CHARSET, 1
.equ OUT_DEFAULT_PRECIS, 0
.equ CLIP_DEFAULT_PRECIS, 0
.equ CLEARTYPE_QUALITY, 5
.equ DEFAULT_PITCH, 0
.equ INVALID_HANDLE_VALUE, -1
.equ FILE_ATTRIBUTE_DIRECTORY, 0x10
.equ FILE_ATTRIBUTE_REPARSE_POINT, 0x400
.equ GENERIC_WRITE, 0x40000000
.equ FILE_SHARE_READ, 1
.equ CREATE_ALWAYS, 2
.equ FILE_ATTRIBUTE_NORMAL, 0x80
.equ MAX_SCAN_DEPTH, 24
.equ MAX_SCAN_ITEMS, 10000
.equ PATH_WBYTES, 4096
.equ FIND_DATA_BYTES, 640
.equ MB_ICONWARNING, 0x30
.equ MB_YESNO, 0x04
.equ IDYES, 6
.equ WORKER_EXIT_WAIT_MS, 3000
.equ CAT_WINDOWS, 1
.equ CAT_BROWSER, 2
.equ CAT_APP, 3
.equ CAT_DEV, 4
.equ CAT_CHAT, 5
.equ CAT_GAME, 6
.equ CAT_MEDIA, 7
.equ CAT_RECYCLE, 8

.section .text
.globl WinMainCRTStartup
.globl WinMain

WinMainCRTStartup:
    sub rsp, 40
    xor ecx, ecx
    call GetModuleHandleW
    mov rcx, rax
    xor edx, edx
    xor r8d, r8d
    mov r9d, SW_SHOWDEFAULT
    call WinMain
    mov ecx, eax
    call ExitProcess

WinMain:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 232

    mov qword ptr hInstance[rip], rcx

    call InitDebugLog
    lea rcx, dbgWinMainEnter[rip]
    call DebugLogRaw

    call InitWideStatics
    lea rcx, dbgWideReady[rip]
    call DebugLogRaw

    mov dword ptr wc[rip + 0], 80
    mov dword ptr wc[rip + 4], 0
    lea rax, WndProc[rip]
    mov qword ptr wc[rip + 8], rax
    mov dword ptr wc[rip + 16], 0
    mov dword ptr wc[rip + 20], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr wc[rip + 24], rax
    mov qword ptr wc[rip + 32], 0

    xor ecx, ecx
    mov edx, IDC_ARROW
    call LoadCursorW
    mov qword ptr wc[rip + 40], rax
    mov qword ptr wc[rip + 48], COLOR_WINDOW_BRUSH
    mov qword ptr wc[rip + 56], 0
    lea rax, classNameW[rip]
    mov qword ptr wc[rip + 64], rax
    mov qword ptr wc[rip + 72], 0

    lea rcx, wc[rip]
    call RegisterClassExW
    test eax, eax
    jnz .class_registered
    lea rcx, dbgRegisterClassFail[rip]
    call DebugLogRaw
    jmp .winmain_exit
.class_registered:
    lea rcx, dbgRegisterClassOk[rip]
    call DebugLogRaw

    mov dword ptr [rsp + 32], CW_USEDEFAULT
    mov dword ptr [rsp + 40], CW_USEDEFAULT
    mov dword ptr [rsp + 48], 1440
    mov dword ptr [rsp + 56], 680
    mov qword ptr [rsp + 64], 0
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, classNameW[rip]
    lea r8, appTitleW[rip]
    mov r9d, WS_OVERLAPPEDWINDOW
    call CreateWindowExW
    mov rbx, rax
    mov qword ptr hMain[rip], rax
    test rax, rax
    jnz .main_window_ok
    lea rcx, dbgMainWindowFail[rip]
    call DebugLogRaw
    jmp .winmain_exit
.main_window_ok:
    lea rcx, dbgMainWindowOk[rip]
    call DebugLogRaw

    mov rcx, rbx
    mov edx, SW_SHOWDEFAULT
    call ShowWindow
    lea rcx, dbgShowWindow[rip]
    call DebugLogRaw

    mov rcx, rbx
    call UpdateWindow
    lea rcx, dbgUpdateWindow[rip]
    call DebugLogRaw
    lea rcx, dbgMsgLoopEnter[rip]
    call DebugLogRaw

.msg_loop:
    lea rcx, msg[rip]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call GetMessageW
    test eax, eax
    jle .msg_done

    lea rcx, msg[rip]
    call TranslateMessage
    lea rcx, msg[rip]
    call DispatchMessageW
    jmp .msg_loop

.msg_done:
    mov eax, dword ptr msg[rip + 8]

.winmain_exit:
    lea rcx, dbgWinMainExit[rip]
    call DebugLogRaw
    call StopWorkerForExit
    test eax, eax
    jz .winmain_skip_log_close
    call DeleteUiFont
    call CloseDebugLog
.winmain_skip_log_close:
    add rsp, 232
    pop rbx
    pop rbp
    ret

WndProc:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 136

    mov rbx, rcx
    cmp edx, WM_CREATE
    je .wm_create
    cmp edx, WM_COMMAND
    je .wm_command
    cmp edx, WM_SIZE
    je .wm_size
    cmp edx, WM_SCAN_DONE
    je .wm_scan_done
    cmp edx, WM_PROGRESS
    je .wm_progress
    cmp edx, WM_DESTROY
    je .wm_destroy

.defproc:
    call DefWindowProcW
    jmp .wnd_exit

.wm_create:
    lea rcx, dbgWmCreateBegin[rip]
    call DebugLogRaw

    mov qword ptr [rsp + 32], 12
    mov qword ptr [rsp + 40], 12
    mov qword ptr [rsp + 48], 120
    mov qword ptr [rsp + 56], 30
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], ID_SCAN
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, scanButtonTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON
    call CreateWindowExW
    mov qword ptr hwndScan[rip], rax

    mov qword ptr [rsp + 32], 144
    mov qword ptr [rsp + 40], 12
    mov qword ptr [rsp + 48], 160
    mov qword ptr [rsp + 56], 30
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], ID_DRYRUN
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, dryRunButtonTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON
    call CreateWindowExW
    mov qword ptr hwndDryRun[rip], rax

    mov qword ptr [rsp + 32], 316
    mov qword ptr [rsp + 40], 12
    mov qword ptr [rsp + 48], 130
    mov qword ptr [rsp + 56], 30
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], ID_CLEAN
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, cleanButtonTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON
    call CreateWindowExW
    mov qword ptr hwndClean[rip], rax

    mov qword ptr [rsp + 32], 458
    mov qword ptr [rsp + 40], 12
    mov qword ptr [rsp + 48], 100
    mov qword ptr [rsp + 56], 30
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], ID_STOP
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, stopButtonTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON
    call CreateWindowExW
    mov qword ptr hwndStop[rip], rax
    mov rcx, rax
    xor edx, edx
    call EnableWindow
    lea rcx, dbgControlsTopReady[rip]
    call DebugLogRaw

    mov qword ptr [rsp + 32], 570
    mov qword ptr [rsp + 40], 16
    mov qword ptr [rsp + 48], 300
    mov qword ptr [rsp + 56], 24
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, staticClassW[rip]
    lea r8, progressIdleTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE
    call CreateWindowExW
    mov qword ptr hwndProgress[rip], rax

    mov qword ptr [rsp + 32], 12
    mov qword ptr [rsp + 40], 50
    mov qword ptr [rsp + 48], 120
    mov qword ptr [rsp + 56], 26
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, catWindowsTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX
    call CreateWindowExW
    mov qword ptr hwndCatWindows[rip], rax

    mov qword ptr [rsp + 32], 144
    mov qword ptr [rsp + 40], 50
    mov qword ptr [rsp + 48], 120
    mov qword ptr [rsp + 56], 26
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, catBrowserTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX
    call CreateWindowExW
    mov qword ptr hwndCatBrowser[rip], rax

    mov qword ptr [rsp + 32], 276
    mov qword ptr [rsp + 40], 50
    mov qword ptr [rsp + 48], 120
    mov qword ptr [rsp + 56], 26
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, catAppTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX
    call CreateWindowExW
    mov qword ptr hwndCatApp[rip], rax

    mov qword ptr [rsp + 32], 408
    mov qword ptr [rsp + 40], 50
    mov qword ptr [rsp + 48], 140
    mov qword ptr [rsp + 56], 26
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, catDevTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX
    call CreateWindowExW
    mov qword ptr hwndCatDev[rip], rax

    mov qword ptr [rsp + 32], 12
    mov qword ptr [rsp + 40], 78
    mov qword ptr [rsp + 48], 120
    mov qword ptr [rsp + 56], 26
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, catChatTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX
    call CreateWindowExW
    mov qword ptr hwndCatChat[rip], rax

    mov qword ptr [rsp + 32], 144
    mov qword ptr [rsp + 40], 78
    mov qword ptr [rsp + 48], 120
    mov qword ptr [rsp + 56], 26
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, catGameTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX
    call CreateWindowExW
    mov qword ptr hwndCatGame[rip], rax

    mov qword ptr [rsp + 32], 276
    mov qword ptr [rsp + 40], 78
    mov qword ptr [rsp + 48], 120
    mov qword ptr [rsp + 56], 26
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, catMediaTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX
    call CreateWindowExW
    mov qword ptr hwndCatMedia[rip], rax

    mov qword ptr [rsp + 32], 408
    mov qword ptr [rsp + 40], 78
    mov qword ptr [rsp + 48], 120
    mov qword ptr [rsp + 56], 26
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, buttonClassW[rip]
    lea r8, catRecycleTextW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX
    call CreateWindowExW
    mov qword ptr hwndCatRecycle[rip], rax

    call InitCategoryChecks
    lea rcx, dbgCategoryControlsReady[rip]
    call DebugLogRaw

    mov qword ptr [rsp + 32], 12
    mov qword ptr [rsp + 40], 114
    mov qword ptr [rsp + 48], 1400
    mov qword ptr [rsp + 56], 510
    mov qword ptr [rsp + 64], rbx
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr hInstance[rip]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    xor ecx, ecx
    lea rdx, editClassW[rip]
    lea r8, emptyStringW[rip]
    mov r9d, WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | WS_HSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_AUTOHSCROLL | ES_READONLY
    call CreateWindowExW
    mov qword ptr hwndLog[rip], rax

    call InitUiFont
    lea rcx, dbgFontReady[rip]
    call DebugLogRaw
    call BuildIntro
    call RefreshLog
    lea rcx, dbgWmCreateDone[rip]
    call DebugLogRaw
    xor eax, eax
    jmp .wnd_exit

.wm_command:
    mov rax, r8
    and eax, 0xffff
    cmp eax, ID_SCAN
    je .do_scan
    cmp eax, ID_DRYRUN
    je .do_dryrun
    cmp eax, ID_STOP
    je .do_stop
    cmp eax, ID_CLEAN
    je .do_clean
    xor eax, eax
    jmp .wnd_exit

.do_scan:
    mov ecx, 1
    call StartWorker
    xor eax, eax
    jmp .wnd_exit

.do_dryrun:
    mov ecx, 2
    call StartWorker
    xor eax, eax
    jmp .wnd_exit

.do_clean:
    call ConfirmClean
    cmp eax, IDYES
    jne .clean_cancel
    mov ecx, 3
    call StartWorker
.clean_cancel:
    xor eax, eax
    jmp .wnd_exit

.do_stop:
    mov qword ptr scanCancel[rip], 1
    call MarkStopRequested
    xor eax, eax
    jmp .wnd_exit

.wm_scan_done:
    lea rcx, dbgWmScanDone[rip]
    call DebugLogRaw
    call FinishWorker
    xor eax, eax
    jmp .wnd_exit

.wm_progress:
    call RefreshProgressText
    xor eax, eax
    jmp .wnd_exit

.wm_size:
    mov eax, r9d
    and eax, 0xffff
    sub eax, 24
    cmp eax, 120
    jge .width_ok
    mov eax, 120
.width_ok:
    mov r10d, eax
    mov eax, r9d
    shr eax, 16
    sub eax, 126
    cmp eax, 120
    jge .height_ok
    mov eax, 120
.height_ok:
    mov r11d, eax
    mov rcx, qword ptr hwndLog[rip]
    test rcx, rcx
    jz .size_done
    mov edx, 12
    mov r8d, 114
    mov r9d, r10d
    mov qword ptr [rsp + 32], r11
    mov qword ptr [rsp + 40], TRUE
    call MoveWindow
.size_done:
    xor eax, eax
    jmp .wnd_exit

.wm_destroy:
    mov qword ptr scanCancel[rip], 1
    mov qword ptr hMain[rip], 0
    lea rcx, dbgWmDestroy[rip]
    call DebugLogRaw
    xor ecx, ecx
    call PostQuitMessage
    xor eax, eax

.wnd_exit:
    add rsp, 136
    pop rbx
    pop rbp
    ret

InitDebugLog:
    push rbx
    push rsi
    push rdi
    sub rsp, 64

    mov qword ptr hDebugLog[rip], 0
    xor ecx, ecx
    lea rdx, debugLogPathW[rip]
    mov r8d, 1024
    call GetModuleFileNameW
    test eax, eax
    jz .idl_done

    lea rsi, debugLogPathW[rip]
    xor ebx, ebx
    xor edi, edi
.idl_find_end:
    cmp ebx, 1023
    jae .idl_done
    mov ax, word ptr [rsi + rbx * 2]
    test ax, ax
    jz .idl_have_dir
    cmp ax, 92
    je .idl_mark_slash
    cmp ax, 47
    je .idl_mark_slash
    inc ebx
    jmp .idl_find_end
.idl_mark_slash:
    lea edi, [ebx + 1]
    inc ebx
    jmp .idl_find_end
.idl_have_dir:
    test edi, edi
    jz .idl_done
    mov word ptr [rsi + rdi * 2], 0
    lea rdx, [rsi + rdi * 2]
    lea rcx, debugLogFilePrefix[rip]
    call AppendAsciiToWide
    mov rdi, rax

    lea rcx, debugLogTime[rip]
    call GetLocalTime
    movzx ecx, word ptr debugLogTime[rip + 0]
    mov rdx, rdi
    call AppendWide4Digits
    mov rdi, rax
    mov ecx, 45
    mov rdx, rdi
    call AppendWideChar
    mov rdi, rax
    movzx ecx, word ptr debugLogTime[rip + 2]
    mov rdx, rdi
    call AppendWide2Digits
    mov rdi, rax
    movzx ecx, word ptr debugLogTime[rip + 6]
    mov rdx, rdi
    call AppendWide2Digits
    mov rdi, rax
    mov ecx, 95
    mov rdx, rdi
    call AppendWideChar
    mov rdi, rax
    movzx ecx, word ptr debugLogTime[rip + 8]
    mov rdx, rdi
    call AppendWide2Digits
    mov rdi, rax
    movzx ecx, word ptr debugLogTime[rip + 10]
    mov rdx, rdi
    call AppendWide2Digits
    mov rdi, rax
    movzx ecx, word ptr debugLogTime[rip + 12]
    mov rdx, rdi
    call AppendWide2Digits
    mov rdi, rax
    lea rcx, debugLogFileSuffix[rip]
    mov rdx, rdi
    call AppendAsciiToWide

    mov qword ptr [rsp + 32], CREATE_ALWAYS
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    lea rcx, debugLogPathW[rip]
    mov edx, GENERIC_WRITE
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    call CreateFileW
    cmp rax, INVALID_HANDLE_VALUE
    je .idl_done
    mov qword ptr hDebugLog[rip], rax

    lea rcx, utf8Bom[rip]
    mov edx, 3
    call DebugLogWriteBytes

.idl_done:
    add rsp, 64
    pop rdi
    pop rsi
    pop rbx
    ret

CloseDebugLog:
    sub rsp, 40
    mov rcx, qword ptr hDebugLog[rip]
    test rcx, rcx
    jz .cdl_done
    call FlushFileBuffers
    mov rcx, qword ptr hDebugLog[rip]
    call CloseHandle
    mov qword ptr hDebugLog[rip], 0
.cdl_done:
    add rsp, 40
    ret

StopWorkerForExit:
    sub rsp, 40
    mov qword ptr scanCancel[rip], 1
    mov rcx, qword ptr hWorker[rip]
    test rcx, rcx
    jz .swfe_safe
    mov edx, WORKER_EXIT_WAIT_MS
    call WaitForSingleObject
    test eax, eax
    jne .swfe_timeout
    mov rcx, qword ptr hWorker[rip]
    call CloseHandle
    mov qword ptr hWorker[rip], 0
.swfe_safe:
    mov eax, 1
    jmp .swfe_done
.swfe_timeout:
    mov rcx, qword ptr hWorker[rip]
    call CloseHandle
    mov qword ptr hWorker[rip], 0
    xor eax, eax
.swfe_done:
    add rsp, 40
    ret

DebugLogRaw:
    push rsi
    sub rsp, 32
    mov rsi, rcx
    cmp qword ptr hDebugLog[rip], 0
    je .dlr_done
    xor edx, edx
.dlr_len:
    mov al, byte ptr [rsi + rdx]
    test al, al
    jz .dlr_have_len
    inc edx
    jmp .dlr_len
.dlr_have_len:
    mov rcx, rsi
    call DebugLogWriteBytes
    lea rcx, debugCrlf[rip]
    mov edx, 2
    call DebugLogWriteBytes
.dlr_done:
    add rsp, 32
    pop rsi
    ret

DebugLogWriteBytes:
    sub rsp, 56
    mov r8d, edx
    mov rdx, rcx
    mov rcx, qword ptr hDebugLog[rip]
    lea r9, [rsp + 48]
    mov qword ptr [rsp + 32], 0
    call WriteFile
    mov rcx, qword ptr hDebugLog[rip]
    call FlushFileBuffers
    add rsp, 56
    ret

AppendAsciiToWide:
    mov rax, rdx
.aatw_loop:
    mov dl, byte ptr [rcx]
    test dl, dl
    jz .aatw_done
    movzx edx, dl
    mov word ptr [rax], dx
    add rax, 2
    inc rcx
    jmp .aatw_loop
.aatw_done:
    mov word ptr [rax], 0
    ret

AppendWideChar:
    mov word ptr [rdx], cx
    lea rax, [rdx + 2]
    mov word ptr [rax], 0
    ret

AppendWide2Digits:
    push rbx
    push rsi
    sub rsp, 32
    mov rsi, rdx
    mov eax, ecx
    xor edx, edx
    mov ebx, 10
    div ebx
    mov ebx, edx
    add al, 48
    movzx ecx, al
    mov rdx, rsi
    call AppendWideChar
    mov rsi, rax
    mov ecx, ebx
    add ecx, 48
    mov rdx, rsi
    call AppendWideChar
    add rsp, 32
    pop rsi
    pop rbx
    ret

AppendWide4Digits:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rdi, rdx
    mov eax, ecx
    xor edx, edx
    mov ebx, 1000
    div ebx
    mov esi, edx
    mov ecx, eax
    add ecx, 48
    mov rdx, rdi
    call AppendWideChar
    mov rdi, rax

    mov eax, esi
    xor edx, edx
    mov ebx, 100
    div ebx
    mov esi, edx
    mov ecx, eax
    add ecx, 48
    mov rdx, rdi
    call AppendWideChar
    mov rdi, rax

    mov eax, esi
    xor edx, edx
    mov ebx, 10
    div ebx
    mov esi, edx
    mov ecx, eax
    add ecx, 48
    mov rdx, rdi
    call AppendWideChar
    mov rdi, rax

    mov ecx, esi
    add ecx, 48
    mov rdx, rdi
    call AppendWideChar
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

InitWideStatics:
    sub rsp, 40

    lea rcx, className[rip]
    lea rdx, classNameW[rip]
    mov r8d, 128
    call ConvertUtf8ToWide

    lea rcx, appTitle[rip]
    lea rdx, appTitleW[rip]
    mov r8d, 128
    call ConvertUtf8ToWide

    lea rcx, buttonClass[rip]
    lea rdx, buttonClassW[rip]
    mov r8d, 32
    call ConvertUtf8ToWide

    lea rcx, editClass[rip]
    lea rdx, editClassW[rip]
    mov r8d, 32
    call ConvertUtf8ToWide

    lea rcx, staticClass[rip]
    lea rdx, staticClassW[rip]
    mov r8d, 32
    call ConvertUtf8ToWide

    lea rcx, scanButtonText[rip]
    lea rdx, scanButtonTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, dryRunButtonText[rip]
    lea rdx, dryRunButtonTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, cleanButtonText[rip]
    lea rdx, cleanButtonTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, catWindowsText[rip]
    lea rdx, catWindowsTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, catBrowserText[rip]
    lea rdx, catBrowserTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, catAppText[rip]
    lea rdx, catAppTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, catDevText[rip]
    lea rdx, catDevTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, catChatText[rip]
    lea rdx, catChatTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, catGameText[rip]
    lea rdx, catGameTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, catMediaText[rip]
    lea rdx, catMediaTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, catRecycleText[rip]
    lea rdx, catRecycleTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, progressIdleText[rip]
    lea rdx, progressIdleTextW[rip]
    mov r8d, 128
    call ConvertUtf8ToWide

    lea rcx, stopButtonText[rip]
    lea rdx, stopButtonTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, stoppingButtonText[rip]
    lea rdx, stoppingButtonTextW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, emptyString[rip]
    lea rdx, emptyStringW[rip]
    mov r8d, 4
    call ConvertUtf8ToWide

    lea rcx, fontFace[rip]
    lea rdx, fontFaceW[rip]
    mov r8d, 64
    call ConvertUtf8ToWide

    lea rcx, confirmCleanTitle[rip]
    lea rdx, confirmCleanTitleW[rip]
    mov r8d, 128
    call ConvertUtf8ToWide

    lea rcx, confirmCleanText[rip]
    lea rdx, confirmCleanTextW[rip]
    mov r8d, 512
    call ConvertUtf8ToWide

    add rsp, 40
    ret

InitUiFont:
    sub rsp, 120

    mov dword ptr [rsp + 32], FW_NORMAL
    mov dword ptr [rsp + 40], 0
    mov dword ptr [rsp + 48], 0
    mov dword ptr [rsp + 56], 0
    mov dword ptr [rsp + 64], DEFAULT_CHARSET
    mov dword ptr [rsp + 72], OUT_DEFAULT_PRECIS
    mov dword ptr [rsp + 80], CLIP_DEFAULT_PRECIS
    mov dword ptr [rsp + 88], CLEARTYPE_QUALITY
    mov dword ptr [rsp + 96], DEFAULT_PITCH
    lea rax, fontFaceW[rip]
    mov qword ptr [rsp + 104], rax
    mov ecx, -16
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call CreateFontW
    mov qword ptr hUiFont[rip], rax
    test rax, rax
    jz .font_done

    mov rcx, qword ptr hwndScan[rip]
    mov r8, rax
    call SendFontIfHwnd

    mov rcx, qword ptr hwndDryRun[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndClean[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndCatWindows[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndCatBrowser[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndCatApp[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndCatDev[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndCatChat[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndCatGame[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndCatMedia[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndCatRecycle[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndProgress[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndLog[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

    mov rcx, qword ptr hwndStop[rip]
    mov r8, qword ptr hUiFont[rip]
    call SendFontIfHwnd

.font_done:
    add rsp, 120
    ret

DeleteUiFont:
    sub rsp, 40
    mov rcx, qword ptr hUiFont[rip]
    test rcx, rcx
    jz .duf_done
    call DeleteObject
    mov qword ptr hUiFont[rip], 0
.duf_done:
    add rsp, 40
    ret

SendFontIfHwnd:
    sub rsp, 40
    test rcx, rcx
    jz .sfih_done
    mov edx, WM_SETFONT
    mov r9d, TRUE
    call SendMessageW
.sfih_done:
    add rsp, 40
    ret

SetTextIfHwnd:
    sub rsp, 40
    test rcx, rcx
    jz .stih_done
    call SetWindowTextW
.stih_done:
    add rsp, 40
    ret

SetCheckIfHwnd:
    sub rsp, 40
    test rcx, rcx
    jz .scih_done
    mov edx, BM_SETCHECK
    xor r9d, r9d
    call SendMessageW
.scih_done:
    add rsp, 40
    ret

ConvertUtf8ToWide:
    push rbx
    sub rsp, 48
    mov rbx, rdx
    mov word ptr [rbx], 0
    mov qword ptr [rsp + 32], rdx
    mov qword ptr [rsp + 40], r8
    mov r8, rcx
    mov ecx, CP_UTF8
    xor edx, edx
    mov r9d, -1
    call MultiByteToWideChar
    test eax, eax
    jnz .cutw_done
    mov word ptr [rbx], 0
.cutw_done:
    add rsp, 48
    pop rbx
    ret

ConvertWideToUtf8:
    push rbx
    sub rsp, 64
    mov rbx, rdx
    mov byte ptr [rbx], 0
    mov qword ptr [rsp + 32], rdx
    mov qword ptr [rsp + 40], r8
    mov qword ptr [rsp + 48], 0
    mov qword ptr [rsp + 56], 0
    mov r8, rcx
    mov ecx, CP_UTF8
    xor edx, edx
    mov r9d, -1
    call WideCharToMultiByte
    test eax, eax
    jnz .cwtu_done
    mov byte ptr [rbx], 0
.cwtu_done:
    add rsp, 64
    pop rbx
    ret

ConfirmClean:
    sub rsp, 40
    mov qword ptr [rsp + 32], MB_YESNO | MB_ICONWARNING
    mov rcx, qword ptr hMain[rip]
    lea rdx, confirmCleanTextW[rip]
    lea r8, confirmCleanTitleW[rip]
    mov r9d, MB_YESNO | MB_ICONWARNING
    call MessageBoxW
    add rsp, 40
    ret

StartWorker:
    push rbx
    sub rsp, 48

    mov ebx, ecx
    lea rcx, dbgWorkerStart[rip]
    call DebugLogRaw
    cmp qword ptr hWorker[rip], 0
    je .sw_start
    lea rcx, alreadyRunningText[rip]
    call AppendLine
    call RefreshLog
    jmp .sw_done

.sw_start:
    mov dword ptr workerMode[rip], ebx
    mov qword ptr scanCancel[rip], 0
    call SnapshotCategoryChecks
    cmp ebx, 3
    jne .sw_no_clean_progress
    call CountSelectedCleanTargets
    call RefreshProgressText
    jmp .sw_progress_ready
.sw_no_clean_progress:
    mov qword ptr progressDone[rip], 0
    mov qword ptr progressTotal[rip], 0
    call RefreshProgressText
.sw_progress_ready:
    call ResetLog
    lea rcx, workerStartText[rip]
    call AppendLine
    call RefreshLog

    mov rcx, qword ptr hwndScan[rip]
    xor edx, edx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndDryRun[rip]
    xor edx, edx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndClean[rip]
    xor edx, edx
    call EnableWindowIfHwnd
    xor ecx, ecx
    call SetCategoryControlsEnabled
    mov rcx, qword ptr hwndStop[rip]
    mov edx, TRUE
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndStop[rip]
    lea rdx, stopButtonTextW[rip]
    call SetTextIfHwnd

    mov qword ptr [rsp + 32], 0
    lea rax, threadId[rip]
    mov qword ptr [rsp + 40], rax
    xor ecx, ecx
    xor edx, edx
    lea r8, WorkerProc[rip]
    mov r9, rbx
    call CreateThread
    mov qword ptr hWorker[rip], rax
    test rax, rax
    jnz .sw_done

    mov rcx, qword ptr hwndScan[rip]
    mov edx, TRUE
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndDryRun[rip]
    mov edx, TRUE
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndClean[rip]
    mov edx, TRUE
    call EnableWindowIfHwnd
    mov ecx, TRUE
    call SetCategoryControlsEnabled
    mov rcx, qword ptr hwndStop[rip]
    xor edx, edx
    call EnableWindowIfHwnd
    call ResetLog
    lea rcx, workerFailText[rip]
    call AppendLine
    call RefreshLog

.sw_done:
    add rsp, 48
    pop rbx
    ret

WorkerProc:
    sub rsp, 40
    cmp ecx, 1
    je .wp_scan
    cmp ecx, 3
    je .wp_clean
    lea rcx, dbgWorkerDryRun[rip]
    call DebugLogRaw
    call BuildDryRunLog
    jmp .wp_post
.wp_scan:
    lea rcx, dbgWorkerScan[rip]
    call DebugLogRaw
    call BuildScanLog
    jmp .wp_post
.wp_clean:
    lea rcx, dbgWorkerClean[rip]
    call DebugLogRaw
    call BuildCleanLog
.wp_post:
    lea rcx, dbgWorkerBuildDone[rip]
    call DebugLogRaw
    mov rcx, qword ptr hMain[rip]
    test rcx, rcx
    jz .wp_post_done
    mov edx, WM_SCAN_DONE
    xor r8d, r8d
    xor r9d, r9d
    call PostMessageW
.wp_post_done:
    lea rcx, dbgWorkerPostedDone[rip]
    call DebugLogRaw
    xor eax, eax
    add rsp, 40
    ret

FinishWorker:
    sub rsp, 40
    lea rcx, dbgFinishWorkerEnter[rip]
    call DebugLogRaw
    mov rcx, qword ptr hWorker[rip]
    test rcx, rcx
    jz .fw_no_handle
    mov edx, WORKER_EXIT_WAIT_MS
    call WaitForSingleObject
    mov rcx, qword ptr hWorker[rip]
    call CloseHandle
    mov qword ptr hWorker[rip], 0
.fw_no_handle:
    mov rcx, qword ptr hwndScan[rip]
    mov edx, TRUE
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndDryRun[rip]
    mov edx, TRUE
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndClean[rip]
    mov edx, TRUE
    call EnableWindowIfHwnd
    mov ecx, TRUE
    call SetCategoryControlsEnabled
    mov rcx, qword ptr hwndStop[rip]
    xor edx, edx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndStop[rip]
    lea rdx, stopButtonTextW[rip]
    call SetTextIfHwnd
    cmp dword ptr workerMode[rip], 3
    jne .fw_idle_progress
    mov rax, qword ptr progressTotal[rip]
    mov qword ptr progressDone[rip], rax
    call RefreshProgressText
    jmp .fw_refresh_log
.fw_idle_progress:
    call RefreshProgressText
.fw_refresh_log:
    call RefreshLog
    lea rcx, dbgFinishWorkerDone[rip]
    call DebugLogRaw
    add rsp, 40
    ret

MarkStopRequested:
    sub rsp, 40
    mov rcx, qword ptr hwndStop[rip]
    lea rdx, stoppingButtonTextW[rip]
    call SetTextIfHwnd
    add rsp, 40
    ret

InitCategoryChecks:
    sub rsp, 40
    mov rcx, qword ptr hwndCatWindows[rip]
    mov r8d, BST_CHECKED
    call SetCheckIfHwnd
    mov rcx, qword ptr hwndCatBrowser[rip]
    mov r8d, BST_CHECKED
    call SetCheckIfHwnd
    mov rcx, qword ptr hwndCatApp[rip]
    mov r8d, BST_CHECKED
    call SetCheckIfHwnd
    mov rcx, qword ptr hwndCatDev[rip]
    mov r8d, BST_CHECKED
    call SetCheckIfHwnd
    mov rcx, qword ptr hwndCatChat[rip]
    xor r8d, r8d
    call SetCheckIfHwnd
    mov rcx, qword ptr hwndCatGame[rip]
    mov r8d, BST_CHECKED
    call SetCheckIfHwnd
    mov rcx, qword ptr hwndCatMedia[rip]
    mov r8d, BST_CHECKED
    call SetCheckIfHwnd
    mov rcx, qword ptr hwndCatRecycle[rip]
    xor r8d, r8d
    call SetCheckIfHwnd
    add rsp, 40
    ret

SnapshotCategoryChecks:
    sub rsp, 40
    mov rcx, qword ptr hwndCatWindows[rip]
    call GetCheckState
    mov qword ptr catWindowsSelected[rip], rax
    mov rcx, qword ptr hwndCatBrowser[rip]
    call GetCheckState
    mov qword ptr catBrowserSelected[rip], rax
    mov rcx, qword ptr hwndCatApp[rip]
    call GetCheckState
    mov qword ptr catAppSelected[rip], rax
    mov rcx, qword ptr hwndCatDev[rip]
    call GetCheckState
    mov qword ptr catDevSelected[rip], rax
    mov rcx, qword ptr hwndCatChat[rip]
    call GetCheckState
    mov qword ptr catChatSelected[rip], rax
    mov rcx, qword ptr hwndCatGame[rip]
    call GetCheckState
    mov qword ptr catGameSelected[rip], rax
    mov rcx, qword ptr hwndCatMedia[rip]
    call GetCheckState
    mov qword ptr catMediaSelected[rip], rax
    mov rcx, qword ptr hwndCatRecycle[rip]
    call GetCheckState
    mov qword ptr catRecycleSelected[rip], rax
    add rsp, 40
    ret

GetCheckState:
    sub rsp, 40
    test rcx, rcx
    jz .gcs_unchecked
    mov edx, BM_GETCHECK
    xor r8d, r8d
    xor r9d, r9d
    call SendMessageW
    cmp eax, BST_CHECKED
    sete al
    movzx eax, al
    jmp .gcs_done
.gcs_unchecked:
    xor eax, eax
.gcs_done:
    add rsp, 40
    ret

SetCategoryControlsEnabled:
    push rbx
    sub rsp, 32
    mov ebx, ecx
    mov rcx, qword ptr hwndCatWindows[rip]
    mov edx, ebx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndCatBrowser[rip]
    mov edx, ebx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndCatApp[rip]
    mov edx, ebx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndCatDev[rip]
    mov edx, ebx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndCatChat[rip]
    mov edx, ebx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndCatGame[rip]
    mov edx, ebx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndCatMedia[rip]
    mov edx, ebx
    call EnableWindowIfHwnd
    mov rcx, qword ptr hwndCatRecycle[rip]
    mov edx, ebx
    call EnableWindowIfHwnd
    add rsp, 32
    pop rbx
    ret

EnableWindowIfHwnd:
    sub rsp, 40
    test rcx, rcx
    jz .ewih_done
    call EnableWindow
.ewih_done:
    add rsp, 40
    ret

IsCategorySelected:
    cmp ecx, CAT_WINDOWS
    je .ics_windows
    cmp ecx, CAT_BROWSER
    je .ics_browser
    cmp ecx, CAT_APP
    je .ics_app
    cmp ecx, CAT_DEV
    je .ics_dev
    cmp ecx, CAT_CHAT
    je .ics_chat
    cmp ecx, CAT_GAME
    je .ics_game
    cmp ecx, CAT_MEDIA
    je .ics_media
    cmp ecx, CAT_RECYCLE
    je .ics_recycle
    xor eax, eax
    jmp .ics_done
.ics_windows:
    mov rax, qword ptr catWindowsSelected[rip]
    jmp .ics_done
.ics_browser:
    mov rax, qword ptr catBrowserSelected[rip]
    jmp .ics_done
.ics_app:
    mov rax, qword ptr catAppSelected[rip]
    jmp .ics_done
.ics_dev:
    mov rax, qword ptr catDevSelected[rip]
    jmp .ics_done
.ics_chat:
    mov rax, qword ptr catChatSelected[rip]
    jmp .ics_done
.ics_game:
    mov rax, qword ptr catGameSelected[rip]
    jmp .ics_done
.ics_media:
    mov rax, qword ptr catMediaSelected[rip]
    jmp .ics_done
.ics_recycle:
    mov rax, qword ptr catRecycleSelected[rip]
.ics_done:
    ret

BuildIntro:
    sub rsp, 40
    call ResetLog
    lea rcx, intro1[rip]
    call AppendLine
    lea rcx, intro2[rip]
    call AppendLine
    lea rcx, intro3[rip]
    call AppendLine
    add rsp, 40
    ret

BuildScanLog:
    sub rsp, 40
    call ResetLog
    lea rcx, scanTitle[rip]
    call AppendLine
    lea rcx, legendLine[rip]
    call AppendLine
    lea rcx, dividerLine[rip]
    call AppendLine
    call ResetRunTotals
    call AppendTargetList
    call AppendRunSummaryLine
    cmp qword ptr scanCancel[rip], 0
    je .bsl_done
    lea rcx, canceledText[rip]
    call AppendLine
.bsl_done:
    add rsp, 40
    ret

BuildDryRunLog:
    sub rsp, 40
    call ResetLog
    lea rcx, dryRunTitle[rip]
    call AppendLine
    lea rcx, dryRunNotice1[rip]
    call AppendLine
    lea rcx, dryRunNotice2[rip]
    call AppendLine
    lea rcx, dividerLine[rip]
    call AppendLine
    call ResetRunTotals
    call AppendTargetList
    call AppendRunSummaryLine
    cmp qword ptr scanCancel[rip], 0
    je .bdl_done
    lea rcx, canceledText[rip]
    call AppendLine
.bdl_done:
    add rsp, 40
    ret

BuildCleanLog:
    sub rsp, 40
    call ResetLog
    lea rcx, cleanTitle[rip]
    call AppendLine
    lea rcx, cleanNotice1[rip]
    call AppendLine
    lea rcx, cleanNotice2[rip]
    call AppendLine
    lea rcx, dividerLine[rip]
    call AppendLine
    call ResetRunTotals
    call AppendTargetList
    call AppendRunSummaryLine
    cmp qword ptr scanCancel[rip], 0
    je .bcl_done
    lea rcx, canceledText[rip]
    call AppendLine
.bcl_done:
    add rsp, 40
    ret

AppendTargetList:
    push rbx
    push rsi
    push rdi
    sub rsp, 32

    lea rsi, targetTable[rip]
.target_loop:
    cmp qword ptr scanCancel[rip], 0
    jne .target_done
    mov rax, qword ptr [rsi]
    test rax, rax
    jz .target_done

    mov rcx, qword ptr [rsi + 8]
    lea rdx, pathTemplateW[rip]
    mov r8d, 2048
    call ConvertUtf8ToWide

    lea rcx, pathTemplateW[rip]
    lea rdx, pathBufferW[rip]
    mov r8d, 2048
    call ExpandEnvironmentStringsW
    test eax, eax
    jz .use_template
    cmp eax, 2048
    ja .use_template

    lea rcx, pathBufferW[rip]
    lea rdx, pathBuffer[rip]
    mov r8d, 4096
    call ConvertWideToUtf8
    jmp .path_ready

.use_template:
    lea rcx, pathBuffer[rip]
    call ClearPathBuffer
    mov rcx, qword ptr [rsi + 8]
    lea rdx, pathBuffer[rip]
    call CopyCString
    lea rcx, pathBuffer[rip]
    lea rdx, pathBufferW[rip]
    mov r8d, 2048
    call ConvertUtf8ToWide

.path_ready:
    lea rcx, pathBufferW[rip]
    call GetFileAttributesW
    mov dword ptr targetAttrs[rip], eax
    cmp eax, INVALID_FILE_ATTRIBUTES
    setne r8b
    movzx r8d, r8b
    mov dword ptr targetExists[rip], r8d
    test r8d, r8d
    jz .count_missing
    inc qword ptr totalExistingTargets[rip]
    jmp .count_done
.count_missing:
    inc qword ptr totalMissingTargets[rip]
.count_done:
    test r8d, r8d
    jz .stats_done
    call ResetScanStats
    mov eax, dword ptr targetAttrs[rip]
    test eax, FILE_ATTRIBUTE_REPARSE_POINT
    jnz .stats_skip_root
    test eax, FILE_ATTRIBUTE_DIRECTORY
    jz .stats_skip_root
    lea rcx, pathBufferW[rip]
    xor edx, edx
    call ScanDirectoryW
    mov rax, qword ptr scanBytes[rip]
    add qword ptr totalScanBytes[rip], rax
    mov rax, qword ptr scanFiles[rip]
    add qword ptr totalScanFiles[rip], rax
    mov rax, qword ptr scanDirs[rip]
    add qword ptr totalScanDirs[rip], rax
    mov rax, qword ptr scanSkipped[rip]
    add qword ptr totalScanSkipped[rip], rax
    cmp qword ptr scanTruncated[rip], 0
    je .stats_done
    inc qword ptr totalTruncatedTargets[rip]
    jmp .stats_done
.stats_skip_root:
    inc qword ptr scanSkipped[rip]
    inc qword ptr totalScanSkipped[rip]
.stats_done:

    mov rcx, qword ptr [rsi]
    lea rdx, pathBuffer[rip]
    mov r9, qword ptr [rsi + 16]
    mov rax, qword ptr [rsi + 24]
    mov qword ptr targetCleanDefault[rip], rax
    mov rax, qword ptr [rsi + 32]
    mov qword ptr targetCategory[rip], rax
    call AppendStatusLine

    cmp dword ptr workerMode[rip], 3
    jne .target_next
    cmp qword ptr scanCancel[rip], 0
    jne .target_next
    cmp qword ptr targetCleanDefault[rip], 1
    jne .progress_checked
    mov rcx, qword ptr targetCategory[rip]
    call IsCategorySelected
    test eax, eax
    jz .progress_checked
    inc qword ptr progressDone[rip]
    call PostProgressUpdate
.progress_checked:
    cmp dword ptr targetExists[rip], 0
    je .target_next
    cmp qword ptr targetCleanDefault[rip], 1
    jne .clean_skip_policy
    mov rcx, qword ptr targetCategory[rip]
    call IsCategorySelected
    test eax, eax
    jz .clean_skip_category
    lea rcx, pathBufferW[rip]
    call GetFileAttributesW
    cmp eax, INVALID_FILE_ATTRIBUTES
    je .clean_skip_path
    test eax, FILE_ATTRIBUTE_REPARSE_POINT
    jnz .clean_skip_path
    test eax, FILE_ATTRIBUTE_DIRECTORY
    jz .clean_skip_path
    cmp qword ptr targetCategory[rip], CAT_RECYCLE
    je .clean_path_ok
    lea rcx, pathBufferW[rip]
    call IsSafeCleanRootW
    test eax, eax
    jz .clean_skip_path
.clean_path_ok:
    call ResetCleanStats
    lea rcx, pathBufferW[rip]
    xor edx, edx
    call CleanDirectoryChildrenW
    mov rax, qword ptr cleanFiles[rip]
    add qword ptr totalCleanFiles[rip], rax
    mov rax, qword ptr cleanDirs[rip]
    add qword ptr totalCleanDirs[rip], rax
    mov rax, qword ptr cleanFailed[rip]
    add qword ptr totalCleanFailed[rip], rax
    mov rax, qword ptr cleanSkipped[rip]
    add qword ptr totalCleanSkipped[rip], rax
    call AppendCleanSummaryLine
    jmp .target_next

.clean_skip_policy:
    inc qword ptr totalCleanSkippedTargets[rip]
    lea rcx, cleanPolicySkipText[rip]
    call AppendLine
    jmp .target_next

.clean_skip_category:
    inc qword ptr totalCleanSkippedTargets[rip]
    lea rcx, cleanCategorySkipText[rip]
    call AppendLine
    jmp .target_next

.clean_skip_path:
    inc qword ptr totalCleanSkippedTargets[rip]
    lea rcx, cleanPathSkipText[rip]
    call AppendLine

.target_next:
    add rsi, 40
    jmp .target_loop

.target_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

CountSelectedCleanTargets:
    push rsi
    sub rsp, 32
    mov qword ptr progressDone[rip], 0
    mov qword ptr progressTotal[rip], 0
    lea rsi, targetTable[rip]
.csct_loop:
    mov rax, qword ptr [rsi]
    test rax, rax
    jz .csct_done
    cmp qword ptr [rsi + 24], 1
    jne .csct_next
    mov rcx, qword ptr [rsi + 32]
    call IsCategorySelected
    test eax, eax
    jz .csct_next
    inc qword ptr progressTotal[rip]
.csct_next:
    add rsi, 40
    jmp .csct_loop
.csct_done:
    add rsp, 32
    pop rsi
    ret

PostProgressUpdate:
    sub rsp, 40
    mov rcx, qword ptr hMain[rip]
    test rcx, rcx
    jz .ppu_done
    mov edx, WM_PROGRESS
    xor r8d, r8d
    xor r9d, r9d
    call PostMessageW
.ppu_done:
    add rsp, 40
    ret

AppendStatusLine:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40

    mov rbx, rcx
    mov rsi, rdx
    mov edi, r8d
    mov r12, r9

    test edi, edi
    jz .missing
    lea rcx, statusExists[rip]
    jmp .status_emit
.missing:
    lea rcx, statusMissing[rip]
.status_emit:
    call AppendRaw
    mov rcx, rbx
    call AppendRaw
    lea rcx, sepText[rip]
    call AppendRaw
    mov rcx, r12
    call AppendRaw
    lea rcx, sepText[rip]
    call AppendRaw
    cmp qword ptr targetCleanDefault[rip], 1
    jne .policy_disabled
    lea rcx, policyEnabledText[rip]
    jmp .policy_emit
.policy_disabled:
    lea rcx, policyDisabledText[rip]
.policy_emit:
    call AppendRaw
    lea rcx, sepText[rip]
    call AppendRaw
    mov rcx, qword ptr targetCategory[rip]
    call AppendCategoryName
    test edi, edi
    jz .append_path
    lea rcx, statSizeText[rip]
    call AppendRaw
    mov rcx, qword ptr scanBytes[rip]
    call AppendSizeHuman
    lea rcx, statBytesText[rip]
    call AppendRaw
    mov rcx, qword ptr scanFiles[rip]
    call AppendUInt64
    lea rcx, statDirsText[rip]
    call AppendRaw
    mov rcx, qword ptr scanDirs[rip]
    call AppendUInt64
    lea rcx, statSkippedText[rip]
    call AppendRaw
    mov rcx, qword ptr scanSkipped[rip]
    call AppendUInt64
    cmp qword ptr scanTruncated[rip], 0
    je .append_path
    lea rcx, statTruncatedText[rip]
    call AppendRaw
.append_path:
    lea rcx, sepText[rip]
    call AppendRaw
    mov rcx, rsi
    call AppendRaw
    call AppendCRLF

    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

AppendCategoryName:
    sub rsp, 40
    cmp ecx, CAT_WINDOWS
    je .acn_windows
    cmp ecx, CAT_BROWSER
    je .acn_browser
    cmp ecx, CAT_APP
    je .acn_app
    cmp ecx, CAT_DEV
    je .acn_dev
    cmp ecx, CAT_CHAT
    je .acn_chat
    cmp ecx, CAT_GAME
    je .acn_game
    cmp ecx, CAT_MEDIA
    je .acn_media
    cmp ecx, CAT_RECYCLE
    je .acn_recycle
    lea rcx, catUnknownText[rip]
    jmp .acn_emit
.acn_windows:
    lea rcx, catWindowsName[rip]
    jmp .acn_emit
.acn_browser:
    lea rcx, catBrowserName[rip]
    jmp .acn_emit
.acn_app:
    lea rcx, catAppName[rip]
    jmp .acn_emit
.acn_dev:
    lea rcx, catDevName[rip]
    jmp .acn_emit
.acn_chat:
    lea rcx, catChatName[rip]
    jmp .acn_emit
.acn_game:
    lea rcx, catGameName[rip]
    jmp .acn_emit
.acn_media:
    lea rcx, catMediaName[rip]
    jmp .acn_emit
.acn_recycle:
    lea rcx, catRecycleName[rip]
.acn_emit:
    call AppendRaw
    add rsp, 40
    ret

ResetRunTotals:
    mov qword ptr totalExistingTargets[rip], 0
    mov qword ptr totalMissingTargets[rip], 0
    mov qword ptr totalScanBytes[rip], 0
    mov qword ptr totalScanFiles[rip], 0
    mov qword ptr totalScanDirs[rip], 0
    mov qword ptr totalScanSkipped[rip], 0
    mov qword ptr totalTruncatedTargets[rip], 0
    mov qword ptr totalCleanFiles[rip], 0
    mov qword ptr totalCleanDirs[rip], 0
    mov qword ptr totalCleanFailed[rip], 0
    mov qword ptr totalCleanSkipped[rip], 0
    mov qword ptr totalCleanSkippedTargets[rip], 0
    ret

AppendRunSummaryLine:
    sub rsp, 40
    lea rcx, dividerLine[rip]
    call AppendLine
    lea rcx, summaryTargetsText[rip]
    call AppendRaw
    mov rcx, qword ptr totalExistingTargets[rip]
    call AppendUInt64
    lea rcx, summaryMissingText[rip]
    call AppendRaw
    mov rcx, qword ptr totalMissingTargets[rip]
    call AppendUInt64
    lea rcx, summarySizeText[rip]
    call AppendRaw
    mov rcx, qword ptr totalScanBytes[rip]
    call AppendSizeHuman
    lea rcx, summaryBytesText[rip]
    call AppendRaw
    mov rcx, qword ptr totalScanFiles[rip]
    call AppendUInt64
    lea rcx, summaryFilesText[rip]
    call AppendRaw
    mov rcx, qword ptr totalScanDirs[rip]
    call AppendUInt64
    lea rcx, summaryDirsText[rip]
    call AppendRaw
    mov rcx, qword ptr totalScanSkipped[rip]
    call AppendUInt64
    lea rcx, summarySkippedText[rip]
    call AppendRaw
    mov rcx, qword ptr totalTruncatedTargets[rip]
    call AppendUInt64
    lea rcx, summaryTruncatedText[rip]
    call AppendRaw
    call AppendCRLF

    cmp dword ptr workerMode[rip], 3
    jne .ars_done
    lea rcx, cleanTotalText[rip]
    call AppendRaw
    mov rcx, qword ptr totalCleanFiles[rip]
    call AppendUInt64
    lea rcx, cleanFilesText[rip]
    call AppendRaw
    mov rcx, qword ptr totalCleanDirs[rip]
    call AppendUInt64
    lea rcx, cleanDirsText[rip]
    call AppendRaw
    mov rcx, qword ptr totalCleanFailed[rip]
    call AppendUInt64
    lea rcx, cleanFailedText[rip]
    call AppendRaw
    mov rcx, qword ptr totalCleanSkipped[rip]
    call AppendUInt64
    lea rcx, cleanTargetSkippedText[rip]
    call AppendRaw
    mov rcx, qword ptr totalCleanSkippedTargets[rip]
    call AppendUInt64
    call AppendCRLF

.ars_done:
    add rsp, 40
    ret

ResetCleanStats:
    mov qword ptr cleanFiles[rip], 0
    mov qword ptr cleanDirs[rip], 0
    mov qword ptr cleanFailed[rip], 0
    mov qword ptr cleanSkipped[rip], 0
    ret

IsSafeCleanRootW:
    push rbx
    push rsi
    sub rsp, 32

    mov rsi, rcx
    xor ebx, ebx
    xor r8d, r8d

    mov ax, word ptr [rsi]
    test ax, ax
    jz .unsafe

    cmp ax, 92
    jne .not_unc
    cmp word ptr [rsi + 2], 92
    je .unsafe

.not_unc:
    cmp word ptr [rsi + 2], 58
    jne .scan_safe_path
    mov ax, word ptr [rsi + 4]
    cmp ax, 92
    je .drive_root_check
    cmp ax, 47
    jne .scan_safe_path
.drive_root_check:
    cmp word ptr [rsi + 6], 0
    je .unsafe

.scan_safe_path:
    cmp ebx, 2047
    jae .unsafe
    mov ax, word ptr [rsi + rbx * 2]
    test ax, ax
    jz .scan_done
    cmp ax, 42
    je .unsafe
    cmp ax, 63
    je .unsafe
    cmp ax, 92
    je .slash_seen
    cmp ax, 47
    jne .next_char
.slash_seen:
    inc r8d
.next_char:
    inc ebx
    jmp .scan_safe_path

.scan_done:
    cmp ebx, 10
    jb .unsafe
    cmp r8d, 2
    jb .unsafe
    mov eax, 1
    jmp .safe_ret

.unsafe:
    xor eax, eax
.safe_ret:
    add rsp, 32
    pop rsi
    pop rbx
    ret

AppendCleanSummaryLine:
    sub rsp, 40
    lea rcx, cleanSummaryText[rip]
    call AppendRaw
    mov rcx, qword ptr cleanFiles[rip]
    call AppendUInt64
    lea rcx, cleanFilesText[rip]
    call AppendRaw
    mov rcx, qword ptr cleanDirs[rip]
    call AppendUInt64
    lea rcx, cleanDirsText[rip]
    call AppendRaw
    mov rcx, qword ptr cleanFailed[rip]
    call AppendUInt64
    lea rcx, cleanFailedText[rip]
    call AppendRaw
    mov rcx, qword ptr cleanSkipped[rip]
    call AppendUInt64
    lea rcx, cleanSkippedText[rip]
    call AppendRaw
    call AppendCRLF
    add rsp, 40
    ret

CleanDirectoryChildrenW:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    mov rbx, rcx
    mov r12d, edx
    cmp qword ptr scanCancel[rip], 0
    je .clean_not_canceled
    jmp .clean_exit

.clean_not_canceled:
    cmp r12d, MAX_SCAN_DEPTH
    jb .clean_depth_ok
    inc qword ptr cleanSkipped[rip]
    jmp .clean_exit

.clean_depth_ok:
    lea rdx, searchSpecW[rip]
    mov rcx, rbx
    call BuildSearchSpecW
    test eax, eax
    jnz .clean_search_spec_ok
    inc qword ptr cleanSkipped[rip]
    jmp .clean_exit
.clean_search_spec_ok:

    mov eax, r12d
    imul rax, rax, FIND_DATA_BYTES
    lea r13, findDataStack[rip]
    add r13, rax

    lea rcx, searchSpecW[rip]
    mov rdx, r13
    call FindFirstFileW
    mov r14, rax
    cmp rax, INVALID_HANDLE_VALUE
    je .clean_exit

.clean_loop:
    cmp qword ptr scanCancel[rip], 0
    jne .clean_close

    lea rcx, [r13 + 44]
    call IsDotEntryW
    test eax, eax
    jnz .clean_next

    mov eax, dword ptr [r13]
    test eax, FILE_ATTRIBUTE_REPARSE_POINT
    jz .clean_not_reparse
    inc qword ptr cleanSkipped[rip]
    jmp .clean_next

.clean_not_reparse:
    mov eax, r12d
    inc eax
    cmp eax, MAX_SCAN_DEPTH
    jb .clean_child_path_ok
    inc qword ptr cleanSkipped[rip]
    jmp .clean_next

.clean_child_path_ok:
    imul r15, rax, PATH_WBYTES
    lea rdi, scanPathStackW[rip]
    add rdi, r15
    mov rcx, rbx
    lea rdx, [r13 + 44]
    mov r8, rdi
    call BuildChildPathW
    test eax, eax
    jnz .clean_child_built
    inc qword ptr cleanSkipped[rip]
    jmp .clean_next

.clean_child_built:

    mov eax, dword ptr [r13]
    test eax, FILE_ATTRIBUTE_DIRECTORY
    jz .clean_file

    mov rcx, rdi
    mov edx, r12d
    inc edx
    call CleanDirectoryChildrenW
    cmp qword ptr scanCancel[rip], 0
    jne .clean_close
    mov rcx, rdi
    call RemoveDirectoryW
    test eax, eax
    jz .clean_dir_failed
    inc qword ptr cleanDirs[rip]
    jmp .clean_next
.clean_dir_failed:
    inc qword ptr cleanFailed[rip]
    jmp .clean_next

.clean_file:
    mov rcx, rdi
    call DeleteFileW
    test eax, eax
    jz .clean_file_failed
    inc qword ptr cleanFiles[rip]
    jmp .clean_next
.clean_file_failed:
    inc qword ptr cleanFailed[rip]

.clean_next:
    mov rcx, r14
    mov rdx, r13
    call FindNextFileW
    test eax, eax
    jnz .clean_loop

.clean_close:
    mov rcx, r14
    call FindClose

.clean_exit:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

ResetScanStats:
    mov qword ptr scanBytes[rip], 0
    mov qword ptr scanFiles[rip], 0
    mov qword ptr scanDirs[rip], 0
    mov qword ptr scanSkipped[rip], 0
    mov qword ptr scanVisited[rip], 0
    mov qword ptr scanTruncated[rip], 0
    ret

ScanDirectoryW:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    mov rbx, rcx
    mov r12d, edx
    cmp qword ptr scanCancel[rip], 0
    je .scan_not_canceled_at_start
    jmp .scan_exit

.scan_not_canceled_at_start:
    cmp qword ptr scanVisited[rip], MAX_SCAN_ITEMS
    jb .scan_visit_ok
    inc qword ptr scanTruncated[rip]
    jmp .scan_exit

.scan_visit_ok:
    cmp r12d, MAX_SCAN_DEPTH
    jb .scan_depth_ok
    inc qword ptr scanTruncated[rip]
    jmp .scan_exit

.scan_depth_ok:
    lea rdx, searchSpecW[rip]
    mov rcx, rbx
    call BuildSearchSpecW
    test eax, eax
    jnz .scan_search_spec_ok
    inc qword ptr scanTruncated[rip]
    jmp .scan_exit
.scan_search_spec_ok:

    mov eax, r12d
    imul rax, rax, FIND_DATA_BYTES
    lea r13, findDataStack[rip]
    add r13, rax

    lea rcx, searchSpecW[rip]
    mov rdx, r13
    call FindFirstFileW
    mov r14, rax
    cmp rax, INVALID_HANDLE_VALUE
    je .scan_exit

.scan_loop:
    cmp qword ptr scanCancel[rip], 0
    jne .scan_close
    inc qword ptr scanVisited[rip]
    cmp qword ptr scanVisited[rip], MAX_SCAN_ITEMS
    jbe .scan_under_cap
    inc qword ptr scanTruncated[rip]
    jmp .scan_close

.scan_under_cap:
    lea rcx, [r13 + 44]
    call IsDotEntryW
    test eax, eax
    jnz .scan_next

    mov eax, dword ptr [r13]
    test eax, FILE_ATTRIBUTE_REPARSE_POINT
    jz .not_reparse
    inc qword ptr scanSkipped[rip]
    jmp .scan_next

.not_reparse:
    test eax, FILE_ATTRIBUTE_DIRECTORY
    jz .scan_file

    inc qword ptr scanDirs[rip]
    mov eax, r12d
    inc eax
    cmp eax, MAX_SCAN_DEPTH
    jb .descend_ok
    inc qword ptr scanTruncated[rip]
    jmp .scan_next

.descend_ok:
    imul r15, rax, PATH_WBYTES
    lea rdi, scanPathStackW[rip]
    add rdi, r15
    mov rcx, rbx
    lea rdx, [r13 + 44]
    mov r8, rdi
    call BuildChildPathW
    test eax, eax
    jnz .scan_child_built
    inc qword ptr scanSkipped[rip]
    jmp .scan_next

.scan_child_built:
    mov rcx, rdi
    mov edx, r12d
    inc edx
    call ScanDirectoryW
    jmp .scan_next

.scan_file:
    inc qword ptr scanFiles[rip]
    mov eax, dword ptr [r13 + 28]
    shl rax, 32
    mov edx, dword ptr [r13 + 32]
    or rax, rdx
    add qword ptr scanBytes[rip], rax

.scan_next:
    mov rcx, r14
    mov rdx, r13
    call FindNextFileW
    test eax, eax
    jnz .scan_loop

.scan_close:
    mov rcx, r14
    call FindClose

.scan_exit:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

BuildSearchSpecW:
    push rbx
    push rsi
    push rdi
    sub rsp, 32

    mov rsi, rcx
    mov rdi, rdx
    xor ebx, ebx
    xor r9d, r9d
.bss_copy:
    cmp ebx, 2044
    jae .bss_too_long
    mov ax, word ptr [rsi + rbx * 2]
    test ax, ax
    jz .bss_finish_base
    mov word ptr [rdi + rbx * 2], ax
    mov r9w, ax
    inc ebx
    jmp .bss_copy
.bss_finish_base:
    cmp ebx, 0
    je .bss_add_slash
    cmp r9w, 92
    je .bss_add_star
    cmp r9w, 47
    je .bss_add_star
.bss_add_slash:
    mov word ptr [rdi + rbx * 2], 92
    inc ebx
.bss_add_star:
    mov word ptr [rdi + rbx * 2], 42
    inc ebx
    mov word ptr [rdi + rbx * 2], 0
    mov eax, 1
    jmp .bss_return

.bss_too_long:
    mov word ptr [rdi + rbx * 2], 0
    xor eax, eax

.bss_return:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

BuildChildPathW:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40

    mov rsi, rcx
    mov r12, rdx
    mov rdi, r8
    xor ebx, ebx
    xor r9d, r9d
.bcp_base:
    cmp ebx, 2044
    jae .bcp_done
    mov ax, word ptr [rsi + rbx * 2]
    test ax, ax
    jz .bcp_base_done
    mov word ptr [rdi + rbx * 2], ax
    mov r9w, ax
    inc ebx
    jmp .bcp_base
.bcp_base_done:
    cmp ebx, 0
    je .bcp_slash
    cmp r9w, 92
    je .bcp_name
    cmp r9w, 47
    je .bcp_name
.bcp_slash:
    mov word ptr [rdi + rbx * 2], 92
    inc ebx
.bcp_name:
    xor r10d, r10d
.bcp_name_loop:
    cmp ebx, 2047
    jae .bcp_done
    mov ax, word ptr [r12 + r10 * 2]
    mov word ptr [rdi + rbx * 2], ax
    test ax, ax
    jz .bcp_ret
    inc ebx
    inc r10d
    jmp .bcp_name_loop
.bcp_done:
    mov word ptr [rdi + rbx * 2], 0
    xor eax, eax
    jmp .bcp_return
.bcp_ret:
    mov eax, 1
.bcp_return:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

IsDotEntryW:
    mov ax, word ptr [rcx]
    cmp ax, 46
    jne .not_dot
    mov ax, word ptr [rcx + 2]
    test ax, ax
    je .is_dot
    cmp ax, 46
    jne .not_dot
    mov ax, word ptr [rcx + 4]
    test ax, ax
    jne .not_dot
.is_dot:
    mov eax, 1
    ret
.not_dot:
    xor eax, eax
    ret

AppendUInt64:
    push rbx
    push rsi
    sub rsp, 40

    mov rax, rcx
    test rax, rax
    jnz .au_nonzero
    lea rcx, zeroText[rip]
    call AppendRaw
    jmp .au_done

.au_nonzero:
    mov ebx, 10
    lea rsi, numberBuffer[rip + 31]
    mov byte ptr [rsi], 0
.au_loop:
    xor edx, edx
    div rbx
    add dl, 48
    dec rsi
    mov byte ptr [rsi], dl
    test rax, rax
    jnz .au_loop
    mov rcx, rsi
    call AppendRaw

.au_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

AppendSizeHuman:
    push rbx
    push rsi
    push rdi
    sub rsp, 32

    mov rdi, rcx
    mov rax, 184467440737095516
    cmp rdi, rax
    ja .ash_too_large

    mov rax, rdi
    mov ebx, 100
    mul rbx
    mov ebx, 1048576
    div rbx
    mov rcx, rax
    call AppendFixed2
    lea rcx, sizeMbText[rip]
    call AppendRaw
    lea rcx, sizeSepText[rip]
    call AppendRaw

    mov rax, rdi
    mov ebx, 100
    mul rbx
    mov ebx, 1073741824
    div rbx
    mov rcx, rax
    call AppendFixed2
    lea rcx, sizeGbText[rip]
    call AppendRaw

    jmp .ash_done
.ash_too_large:
    lea rcx, sizeTooLargeText[rip]
    call AppendRaw

.ash_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

AppendFixed2:
    push rbx
    push rsi
    sub rsp, 40

    mov rax, rcx
    xor edx, edx
    mov ebx, 100
    div rbx
    mov esi, edx
    mov rcx, rax
    call AppendUInt64
    lea rcx, decimalPointText[rip]
    call AppendRaw
    mov eax, esi
    xor edx, edx
    mov ebx, 10
    div rbx
    add al, 48
    mov byte ptr sizeDecimalBuffer[rip], al
    add dl, 48
    mov byte ptr sizeDecimalBuffer[rip + 1], dl
    mov byte ptr sizeDecimalBuffer[rip + 2], 0
    lea rcx, sizeDecimalBuffer[rip]
    call AppendRaw

    add rsp, 40
    pop rsi
    pop rbx
    ret

ResetLog:
    mov qword ptr logPos[rip], 0
    lea rax, logBuffer[rip]
    mov byte ptr [rax], 0
    ret

AppendLine:
    sub rsp, 40
    call AppendRaw
    call AppendCRLF
    add rsp, 40
    ret

AppendRaw:
    mov rdx, qword ptr logPos[rip]
    lea r8, logBuffer[rip]
    add r8, rdx
.append_loop:
    cmp rdx, LOG_LIMIT
    jae .append_done
    mov al, byte ptr [rcx]
    test al, al
    jz .append_done
    mov byte ptr [r8], al
    inc rcx
    inc r8
    inc rdx
    jmp .append_loop
.append_done:
    mov byte ptr [r8], 0
    mov qword ptr logPos[rip], rdx
    ret

AppendCRLF:
    mov rdx, qword ptr logPos[rip]
    cmp rdx, LOG_LIMIT - 2
    jae .crlf_done
    lea r8, logBuffer[rip]
    add r8, rdx
    mov byte ptr [r8], 13
    mov byte ptr [r8 + 1], 10
    mov byte ptr [r8 + 2], 0
    add rdx, 2
    mov qword ptr logPos[rip], rdx
.crlf_done:
    ret

RefreshLog:
    sub rsp, 40
    mov rcx, qword ptr hwndLog[rip]
    test rcx, rcx
    jz .refresh_done
    lea rcx, logBuffer[rip]
    lea rdx, logWide[rip]
    mov r8d, 65536
    call ConvertUtf8ToWide
    mov rcx, qword ptr hwndLog[rip]
    lea rdx, logWide[rip]
    call SetWindowTextW
.refresh_done:
    add rsp, 40
    ret

RefreshProgressText:
    sub rsp, 40
    mov rcx, qword ptr hwndProgress[rip]
    test rcx, rcx
    jz .rpt_done
    call BuildProgressText
    lea rcx, progressBuffer[rip]
    lea rdx, progressWide[rip]
    mov r8d, 512
    call ConvertUtf8ToWide
    mov rcx, qword ptr hwndProgress[rip]
    lea rdx, progressWide[rip]
    call SetWindowTextW
.rpt_done:
    add rsp, 40
    ret

BuildProgressText:
    sub rsp, 40
    call ResetProgressBuffer
    cmp dword ptr workerMode[rip], 3
    je .bpt_clean
    lea rcx, progressIdleText[rip]
    call AppendProgressRaw
    jmp .bpt_done
.bpt_clean:
    lea rcx, progressPrefixText[rip]
    call AppendProgressRaw
    mov rcx, qword ptr progressDone[rip]
    call AppendProgressUInt64
    lea rcx, progressDoneText[rip]
    call AppendProgressRaw
    mov rcx, qword ptr progressTotal[rip]
    mov rax, qword ptr progressDone[rip]
    cmp rcx, rax
    jae .bpt_remaining_ok
    xor ecx, ecx
    jmp .bpt_have_remaining
.bpt_remaining_ok:
    sub rcx, rax
.bpt_have_remaining:
    call AppendProgressUInt64
    lea rcx, progressRemainText[rip]
    call AppendProgressRaw
.bpt_done:
    add rsp, 40
    ret

ResetProgressBuffer:
    mov qword ptr progressPos[rip], 0
    lea rax, progressBuffer[rip]
    mov byte ptr [rax], 0
    ret

AppendProgressRaw:
    mov rdx, qword ptr progressPos[rip]
    lea r8, progressBuffer[rip]
    add r8, rdx
.apr_loop:
    cmp rdx, 510
    jae .apr_done
    mov al, byte ptr [rcx]
    test al, al
    jz .apr_done
    mov byte ptr [r8], al
    inc rcx
    inc r8
    inc rdx
    jmp .apr_loop
.apr_done:
    mov byte ptr [r8], 0
    mov qword ptr progressPos[rip], rdx
    ret

AppendProgressUInt64:
    push rbx
    push rsi
    sub rsp, 40
    mov rax, rcx
    test rax, rax
    jnz .apu_nonzero
    lea rcx, zeroText[rip]
    call AppendProgressRaw
    jmp .apu_done
.apu_nonzero:
    mov ebx, 10
    lea rsi, progressNumberBuffer[rip + 31]
    mov byte ptr [rsi], 0
.apu_loop:
    xor edx, edx
    div rbx
    add dl, 48
    dec rsi
    mov byte ptr [rsi], dl
    test rax, rax
    jnz .apu_loop
    mov rcx, rsi
    call AppendProgressRaw
.apu_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

ClearPathBuffer:
    mov byte ptr [rcx], 0
    ret

# rcx = source, rdx = destination. Copies a bounded C string into pathBuffer.
CopyCString:
    xor r8d, r8d
.copy_loop:
    cmp r8d, 2046
    jae .copy_end
    mov al, byte ptr [rcx + r8]
    mov byte ptr [rdx + r8], al
    test al, al
    jz .copy_ret
    inc r8d
    jmp .copy_loop
.copy_end:
    mov byte ptr [rdx + r8], 0
.copy_ret:
    ret

.section .rdata
className:         .asciz "WinTempViewAsmWindow"
appTitle:          .asciz "winTempView - x64 汇编垃圾清理工具"
buttonClass:       .asciz "BUTTON"
editClass:         .asciz "EDIT"
staticClass:       .asciz "STATIC"
emptyString:       .asciz ""
fontFace:          .asciz "Microsoft YaHei UI"
debugLogFilePrefix:.asciz "winTempView-log-"
debugLogFileSuffix:.asciz ".txt"
utf8Bom:           .byte 0xef, 0xbb, 0xbf
debugCrlf:         .asciz "\r\n"
dbgWinMainEnter:   .asciz "[startup] WinMain enter"
dbgWideReady:      .asciz "[startup] wide strings ready"
dbgRegisterClassOk:.asciz "[startup] RegisterClassExW ok"
dbgRegisterClassFail:.asciz "[startup] RegisterClassExW failed"
dbgMainWindowOk:   .asciz "[startup] main window created"
dbgMainWindowFail: .asciz "[startup] CreateWindowExW main failed"
dbgShowWindow:     .asciz "[startup] ShowWindow done"
dbgUpdateWindow:   .asciz "[startup] UpdateWindow done"
dbgMsgLoopEnter:   .asciz "[startup] entering message loop"
dbgWmCreateBegin:  .asciz "[wm_create] begin"
dbgControlsTopReady:.asciz "[wm_create] top controls ready"
dbgCategoryControlsReady:.asciz "[wm_create] category controls ready"
dbgFontReady:      .asciz "[wm_create] font init done"
dbgWmCreateDone:   .asciz "[wm_create] done"
dbgWmDestroy:      .asciz "[shutdown] WM_DESTROY"
dbgWinMainExit:    .asciz "[shutdown] WinMain exit"
dbgWorkerStart:    .asciz "[action] StartWorker enter"
dbgWorkerScan:     .asciz "[worker] BuildScanLog"
dbgWorkerDryRun:   .asciz "[worker] BuildDryRunLog"
dbgWorkerClean:    .asciz "[worker] BuildCleanLog"
dbgWorkerBuildDone:.asciz "[worker] build routine returned"
dbgWorkerPostedDone:.asciz "[worker] WM_SCAN_DONE posted"
dbgWmScanDone:     .asciz "[ui] WM_SCAN_DONE received"
dbgFinishWorkerEnter:.asciz "[ui] FinishWorker enter"
dbgFinishWorkerDone:.asciz "[ui] FinishWorker done"
scanButtonText:    .asciz "扫描目标"
dryRunButtonText:  .asciz "扫描预估"
cleanButtonText:   .asciz "执行清理"
stopButtonText:    .asciz "停止"
stoppingButtonText:.asciz "停止中..."
progressIdleText:  .asciz "进度：空闲"
progressPrefixText:.asciz "清理进度：已处理 "
progressDoneText:  .asciz " 项 | 剩余 "
progressRemainText:.asciz " 项"
catWindowsText:    .asciz "Windows"
catBrowserText:    .asciz "浏览器"
catAppText:        .asciz "应用"
catDevText:        .asciz "开发工具"
catChatText:       .asciz "聊天数据"
catGameText:       .asciz "游戏平台"
catMediaText:      .asciz "媒体工具"
catRecycleText:    .asciz "回收站"
confirmCleanTitle: .asciz "确认执行清理"
confirmCleanText:  .asciz "将真实删除默认开启、分类已勾选且路径安全的目标内容，不删除目标根目录本身。默认未勾选的分类需要你手动勾选后才会处理。"

intro1:            .asciz "winTempView x64 汇编原型"
intro2:            .asciz "当前版本支持扫描预估、按分类选择、以及真实清理。"
intro3:            .asciz "默认未勾选的分类需要手动勾选后才会参与清理。"
workerStartText:   .asciz "后台扫描已启动，请等待结果。"
workerFailText:    .asciz "后台扫描线程创建失败。"
alreadyRunningText:.asciz "已有扫描任务正在运行。"
canceledText:      .asciz "扫描已按用户请求停止。"
scanTitle:         .asciz "扫描结果：缓存/垃圾目标根目录"
dryRunTitle:       .asciz "扫描预估结果：没有删除任何文件"
dryRunNotice1:     .asciz "该功能只统计目标，不执行删除。"
dryRunNotice2:     .asciz "执行清理时会按照分类勾选状态和规则表处理目标。"
cleanTitle:        .asciz "执行清理结果"
cleanNotice1:      .asciz "本次会真实删除匹配目标的目录内容，但不会删除目标根目录本身。"
cleanNotice2:      .asciz "必须同时满足默认开启、分类勾选、路径安全校验通过；其他目标自动跳过。"
legendLine:        .asciz "[存在] 已找到目标根目录；[缺失] 当前用户配置中没有该目标根目录。"
dividerLine:       .asciz "--------------------------------------------------------------------------"
statusExists:      .asciz "[存在] "
statusMissing:     .asciz "[缺失] "
sepText:           .asciz " | "
statSizeText:      .asciz " | 大小 "
statBytesText:     .asciz " | 文件 "
statDirsText:      .asciz " | 目录 "
statSkippedText:   .asciz " | 跳过 "
statTruncatedText: .asciz " | 已截断"
zeroText:          .asciz "0"
policyEnabledText: .asciz "默认清理:开"
policyDisabledText:.asciz "默认清理:关"
cleanRiskSkipText: .asciz "  清理跳过：规则未启用。"
cleanPolicySkipText:.asciz "  清理跳过：该目标默认未启用清理。"
cleanCategorySkipText:.asciz "  清理跳过：所属分类未勾选。"
cleanPathSkipText: .asciz "  清理跳过：路径安全校验未通过。"
cleanSummaryText:  .asciz "  清理结果：删除文件 "
cleanFilesText:    .asciz " | 删除目录 "
cleanDirsText:     .asciz " | 失败 "
cleanFailedText:   .asciz " | 跳过 "
cleanSkippedText:  .asciz ""
summaryTargetsText:.asciz "总计：存在目标 "
summaryMissingText:.asciz " | 缺失目标 "
summarySizeText:   .asciz " | 预计可释放 "
summaryBytesText:  .asciz " | 文件 "
sizeMbText:        .asciz " MB"
sizeSepText:       .asciz " / "
sizeGbText:        .asciz " GB"
sizeTooLargeText:  .asciz "too large"
decimalPointText:  .asciz "."
summaryFilesText:  .asciz " | 目录 "
summaryDirsText:   .asciz " | 扫描跳过 "
summarySkippedText:.asciz " | 截断目标 "
summaryTruncatedText:.asciz ""
cleanTotalText:    .asciz "清理总计：删除文件 "
cleanTargetSkippedText:.asciz " | 跳过目标 "
catWindowsName:    .asciz "分类:Windows"
catBrowserName:    .asciz "分类:浏览器"
catAppName:        .asciz "分类:应用"
catDevName:        .asciz "分类:开发工具"
catChatName:       .asciz "分类:聊天数据"
catGameName:       .asciz "分类:游戏平台"
catMediaName:      .asciz "分类:媒体工具"
catRecycleName:    .asciz "分类:回收站"
catUnknownText:    .asciz "分类:未知"
riskLow:           .asciz "常规"
riskMedium:        .asciz "扩展"
riskHigh:          .asciz "数据"

nameUserTemp:      .asciz "Windows 用户临时目录"
pathUserTemp:      .asciz "%TEMP%"
nameLocalTemp:     .asciz "Windows 本地临时目录"
pathLocalTemp:     .asciz "%LOCALAPPDATA%\\Temp"
nameInetCache:     .asciz "Windows INetCache"
pathInetCache:     .asciz "%LOCALAPPDATA%\\Microsoft\\Windows\\INetCache"
nameThumbs:        .asciz "Windows 缩略图缓存"
pathThumbs:        .asciz "%LOCALAPPDATA%\\Microsoft\\Windows\\Explorer"
nameCrashDumps:    .asciz "用户崩溃转储"
pathCrashDumps:    .asciz "%LOCALAPPDATA%\\CrashDumps"
nameWer:           .asciz "Windows 错误报告"
pathWer:           .asciz "%LOCALAPPDATA%\\Microsoft\\Windows\\WER"
nameD3D:           .asciz "DirectX 着色器缓存"
pathD3D:           .asciz "%LOCALAPPDATA%\\D3DSCache"
nameDelivery:      .asciz "传递优化缓存"
pathDelivery:      .asciz "%LOCALAPPDATA%\\Microsoft\\Windows\\DeliveryOptimization\\Cache"
nameWinTemp:       .asciz "系统 Windows 临时目录"
pathWinTemp:       .asciz "%WINDIR%\\Temp"
nameRecycleBin:    .asciz "回收站根目录"
pathRecycleBin:    .asciz "%SYSTEMDRIVE%\\$Recycle.Bin"
nameWinUpdate:     .asciz "Windows Update 下载缓存"
pathWinUpdate:     .asciz "%WINDIR%\\SoftwareDistribution\\Download"
nameNvidiaDx:      .asciz "NVIDIA DXCache"
pathNvidiaDx:      .asciz "%LOCALAPPDATA%\\NVIDIA\\DXCache"
nameNvidiaGl:      .asciz "NVIDIA GLCache"
pathNvidiaGl:      .asciz "%LOCALAPPDATA%\\NVIDIA\\GLCache"
nameNvidiaCompute: .asciz "NVIDIA ComputeCache"
pathNvidiaCompute: .asciz "%LOCALAPPDATA%\\NVIDIA\\ComputeCache"
nameAmdDx:         .asciz "AMD DxCache"
pathAmdDx:         .asciz "%LOCALAPPDATA%\\AMD\\DxCache"
nameAmdGl:         .asciz "AMD GLCache"
pathAmdGl:         .asciz "%LOCALAPPDATA%\\AMD\\GLCache"
nameVulkanCache:   .asciz "Vulkan shader cache"
pathVulkanCache:   .asciz "%LOCALAPPDATA%\\vulkan\\cache"
nameIntelShader:   .asciz "Intel shader cache"
pathIntelShader:   .asciz "%LOCALAPPDATA%\\Intel\\ShaderCache"
nameWinCaches:     .asciz "Windows Caches"
pathWinCaches:     .asciz "%LOCALAPPDATA%\\Microsoft\\Windows\\Caches"
nameWinWebCache:   .asciz "Windows WebCache"
pathWinWebCache:   .asciz "%LOCALAPPDATA%\\Microsoft\\Windows\\WebCache"
nameWinFontCache:  .asciz "Windows FontCache"
pathWinFontCache:  .asciz "%WINDIR%\\ServiceProfiles\\LocalService\\AppData\\Local\\FontCache"
nameWinPrefetch:   .asciz "Windows Prefetch"
pathWinPrefetch:   .asciz "%WINDIR%\\Prefetch"
nameWinCbsLogs:    .asciz "Windows CBS Logs"
pathWinCbsLogs:    .asciz "%WINDIR%\\Logs\\CBS"
nameWinDismLogs:   .asciz "Windows DISM Logs"
pathWinDismLogs:   .asciz "%WINDIR%\\Logs\\DISM"
nameDirectXShader: .asciz "Windows DirectX Shader Cache"
pathDirectXShader: .asciz "%LOCALAPPDATA%\\Microsoft\\DirectX Shader Cache"
nameProgramDataWer:.asciz "Windows ProgramData WER"
pathProgramDataWer:.asciz "%PROGRAMDATA%\\Microsoft\\Windows\\WER"
nameWindowsPanther:.asciz "Windows Panther Logs"
pathWindowsPanther:.asciz "%WINDIR%\\Panther"

nameChromeCache:   .asciz "Chrome 默认缓存"
pathChromeCache:   .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Default\\Cache"
nameChromeCode:    .asciz "Chrome 代码缓存"
pathChromeCode:    .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Default\\Code Cache"
nameChromeGpu:     .asciz "Chrome GPU 缓存"
pathChromeGpu:     .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Default\\GPUCache"
nameChromeP1Cache: .asciz "Chrome Profile 1 缓存"
pathChromeP1Cache: .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 1\\Cache"
nameChromeP1Code:  .asciz "Chrome Profile 1 代码缓存"
pathChromeP1Code:  .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 1\\Code Cache"
nameChromeP2Cache: .asciz "Chrome Profile 2 缓存"
pathChromeP2Cache: .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 2\\Cache"
nameChromeP2Code:  .asciz "Chrome Profile 2 代码缓存"
pathChromeP2Code:  .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 2\\Code Cache"
nameChromeP3Cache: .asciz "Chrome Profile 3 Cache"
pathChromeP3Cache: .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 3\\Cache"
nameChromeP3Code:  .asciz "Chrome Profile 3 Code Cache"
pathChromeP3Code:  .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 3\\Code Cache"
nameChromeP3Gpu:   .asciz "Chrome Profile 3 GPUCache"
pathChromeP3Gpu:   .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 3\\GPUCache"
nameChromeP4Cache: .asciz "Chrome Profile 4 Cache"
pathChromeP4Cache: .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 4\\Cache"
nameChromeP4Code:  .asciz "Chrome Profile 4 Code Cache"
pathChromeP4Code:  .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 4\\Code Cache"
nameChromeP4Gpu:   .asciz "Chrome Profile 4 GPUCache"
pathChromeP4Gpu:   .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 4\\GPUCache"
nameChromeP5Cache: .asciz "Chrome Profile 5 Cache"
pathChromeP5Cache: .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 5\\Cache"
nameChromeP5Code:  .asciz "Chrome Profile 5 Code Cache"
pathChromeP5Code:  .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 5\\Code Cache"
nameChromeP5Gpu:   .asciz "Chrome Profile 5 GPUCache"
pathChromeP5Gpu:   .asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Profile 5\\GPUCache"
nameChromeCrashpad:.asciz "Chrome Crashpad"
pathChromeCrashpad:.asciz "%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Crashpad"
nameEdgeCache:     .asciz "Edge 默认缓存"
pathEdgeCache:     .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Default\\Cache"
nameEdgeCode:      .asciz "Edge 代码缓存"
pathEdgeCode:      .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Default\\Code Cache"
nameEdgeGpu:       .asciz "Edge GPU 缓存"
pathEdgeGpu:       .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Default\\GPUCache"
nameEdgeP1Cache:   .asciz "Edge Profile 1 缓存"
pathEdgeP1Cache:   .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 1\\Cache"
nameEdgeP1Code:    .asciz "Edge Profile 1 代码缓存"
pathEdgeP1Code:    .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 1\\Code Cache"
nameEdgeP2Cache:   .asciz "Edge Profile 2 缓存"
pathEdgeP2Cache:   .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 2\\Cache"
nameEdgeP2Code:    .asciz "Edge Profile 2 代码缓存"
pathEdgeP2Code:    .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 2\\Code Cache"
nameEdgeP3Cache:   .asciz "Edge Profile 3 Cache"
pathEdgeP3Cache:   .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 3\\Cache"
nameEdgeP3Code:    .asciz "Edge Profile 3 Code Cache"
pathEdgeP3Code:    .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 3\\Code Cache"
nameEdgeP3Gpu:     .asciz "Edge Profile 3 GPUCache"
pathEdgeP3Gpu:     .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 3\\GPUCache"
nameEdgeP4Cache:   .asciz "Edge Profile 4 Cache"
pathEdgeP4Cache:   .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 4\\Cache"
nameEdgeP4Code:    .asciz "Edge Profile 4 Code Cache"
pathEdgeP4Code:    .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 4\\Code Cache"
nameEdgeP4Gpu:     .asciz "Edge Profile 4 GPUCache"
pathEdgeP4Gpu:     .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 4\\GPUCache"
nameEdgeP5Cache:   .asciz "Edge Profile 5 Cache"
pathEdgeP5Cache:   .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 5\\Cache"
nameEdgeP5Code:    .asciz "Edge Profile 5 Code Cache"
pathEdgeP5Code:    .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 5\\Code Cache"
nameEdgeP5Gpu:     .asciz "Edge Profile 5 GPUCache"
pathEdgeP5Gpu:     .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Profile 5\\GPUCache"
nameEdgeCrashpad:  .asciz "Edge Crashpad"
pathEdgeCrashpad:  .asciz "%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Crashpad"
nameFirefoxRoam:   .asciz "Firefox 配置根目录"
pathFirefoxRoam:   .asciz "%APPDATA%\\Mozilla\\Firefox\\Profiles"
nameFirefoxLocal:  .asciz "Firefox 本地缓存根目录"
pathFirefoxLocal:  .asciz "%LOCALAPPDATA%\\Mozilla\\Firefox\\Profiles"
nameBraveCache:    .asciz "Brave 默认缓存"
pathBraveCache:    .asciz "%LOCALAPPDATA%\\BraveSoftware\\Brave-Browser\\User Data\\Default\\Cache"
nameBraveCode:     .asciz "Brave 代码缓存"
pathBraveCode:     .asciz "%LOCALAPPDATA%\\BraveSoftware\\Brave-Browser\\User Data\\Default\\Code Cache"
nameBraveGpu:      .asciz "Brave GPU 缓存"
pathBraveGpu:      .asciz "%LOCALAPPDATA%\\BraveSoftware\\Brave-Browser\\User Data\\Default\\GPUCache"
nameBraveP1Cache:  .asciz "Brave Profile 1 Cache"
pathBraveP1Cache:  .asciz "%LOCALAPPDATA%\\BraveSoftware\\Brave-Browser\\User Data\\Profile 1\\Cache"
nameBraveP1Code:   .asciz "Brave Profile 1 Code Cache"
pathBraveP1Code:   .asciz "%LOCALAPPDATA%\\BraveSoftware\\Brave-Browser\\User Data\\Profile 1\\Code Cache"
nameBraveP2Cache:  .asciz "Brave Profile 2 Cache"
pathBraveP2Cache:  .asciz "%LOCALAPPDATA%\\BraveSoftware\\Brave-Browser\\User Data\\Profile 2\\Cache"
nameBraveP2Code:   .asciz "Brave Profile 2 Code Cache"
pathBraveP2Code:   .asciz "%LOCALAPPDATA%\\BraveSoftware\\Brave-Browser\\User Data\\Profile 2\\Code Cache"
nameBraveCrashpad: .asciz "Brave Crashpad"
pathBraveCrashpad: .asciz "%LOCALAPPDATA%\\BraveSoftware\\Brave-Browser\\User Data\\Crashpad"
nameOperaCache:    .asciz "Opera Stable 缓存"
pathOperaCache:    .asciz "%APPDATA%\\Opera Software\\Opera Stable\\Cache"
nameOperaCode:     .asciz "Opera Stable 代码缓存"
pathOperaCode:     .asciz "%APPDATA%\\Opera Software\\Opera Stable\\Code Cache"
nameOperaGpu:      .asciz "Opera Stable GPU 缓存"
pathOperaGpu:      .asciz "%APPDATA%\\Opera Software\\Opera Stable\\GPUCache"
nameOperaCrash:    .asciz "Opera Stable crash reports"
pathOperaCrash:    .asciz "%APPDATA%\\Opera Software\\Opera Stable\\Crash Reports"
nameOperaGxCache:  .asciz "Opera GX Cache"
pathOperaGxCache:  .asciz "%APPDATA%\\Opera Software\\Opera GX Stable\\Cache"
nameOperaGxCode:   .asciz "Opera GX Code Cache"
pathOperaGxCode:   .asciz "%APPDATA%\\Opera Software\\Opera GX Stable\\Code Cache"
nameOperaGxGpu:    .asciz "Opera GX GPUCache"
pathOperaGxGpu:    .asciz "%APPDATA%\\Opera Software\\Opera GX Stable\\GPUCache"
nameQQBrowser:     .asciz "QQ 浏览器缓存"
pathQQBrowser:     .asciz "%LOCALAPPDATA%\\Tencent\\QQBrowser\\User Data\\Default\\Cache"
nameQQBrowserCode: .asciz "QQ 浏览器代码缓存"
pathQQBrowserCode: .asciz "%LOCALAPPDATA%\\Tencent\\QQBrowser\\User Data\\Default\\Code Cache"
nameQQBrowserGpu:  .asciz "QQ 浏览器GPU缓存"
pathQQBrowserGpu:  .asciz "%LOCALAPPDATA%\\Tencent\\QQBrowser\\User Data\\Default\\GPUCache"
nameQQBrowserCrashpad:.asciz "QQ Browser Crashpad"
pathQQBrowserCrashpad:.asciz "%LOCALAPPDATA%\\Tencent\\QQBrowser\\User Data\\Crashpad"
nameSogouBrowser:  .asciz "搜狗浏览器缓存"
pathSogouBrowser:  .asciz "%APPDATA%\\SogouExplorer\\Webkit\\Default\\Cache"
nameSogouBrowserCode:.asciz "Sogou Browser Code Cache"
pathSogouBrowserCode:.asciz "%APPDATA%\\SogouExplorer\\Webkit\\Default\\Code Cache"
nameSogouGpu:      .asciz "搜狗浏览器GPU缓存"
pathSogouGpu:      .asciz "%APPDATA%\\SogouExplorer\\Webkit\\Default\\GPUCache"
nameChrome360:     .asciz "360 极速浏览器缓存"
pathChrome360:     .asciz "%LOCALAPPDATA%\\360Chrome\\Chrome\\User Data\\Default\\Cache"
nameChrome360Code: .asciz "360 极速浏览器代码缓存"
pathChrome360Code: .asciz "%LOCALAPPDATA%\\360Chrome\\Chrome\\User Data\\Default\\Code Cache"
nameChrome360Gpu:  .asciz "360 极速浏览器GPU缓存"
pathChrome360Gpu:  .asciz "%LOCALAPPDATA%\\360Chrome\\Chrome\\User Data\\Default\\GPUCache"
nameChrome360XCache:.asciz "360 ChromeX Cache"
pathChrome360XCache:.asciz "%LOCALAPPDATA%\\360ChromeX\\Chrome\\User Data\\Default\\Cache"
nameChrome360XCode:.asciz "360 ChromeX Code Cache"
pathChrome360XCode:.asciz "%LOCALAPPDATA%\\360ChromeX\\Chrome\\User Data\\Default\\Code Cache"
nameChrome360XGpu:.asciz "360 ChromeX GPUCache"
pathChrome360XGpu:.asciz "%LOCALAPPDATA%\\360ChromeX\\Chrome\\User Data\\Default\\GPUCache"
nameBrowser360SafeCache:.asciz "360 Safe Browser Cache"
pathBrowser360SafeCache:.asciz "%APPDATA%\\360se6\\User Data\\Default\\Cache"
nameBrowser360SafeCode:.asciz "360 Safe Browser Code Cache"
pathBrowser360SafeCode:.asciz "%APPDATA%\\360se6\\User Data\\Default\\Code Cache"
nameBrowser360SafeGpu:.asciz "360 Safe Browser GPUCache"
pathBrowser360SafeGpu:.asciz "%APPDATA%\\360se6\\User Data\\Default\\GPUCache"
nameMaxthonCache:  .asciz "Maxthon Browser Cache"
pathMaxthonCache:  .asciz "%LOCALAPPDATA%\\Maxthon\\Application\\User Data\\Default\\Cache"
nameMaxthonCode:   .asciz "Maxthon Browser Code Cache"
pathMaxthonCode:   .asciz "%LOCALAPPDATA%\\Maxthon\\Application\\User Data\\Default\\Code Cache"
nameBrowser2345Cache:.asciz "2345 Explorer Cache"
pathBrowser2345Cache:.asciz "%LOCALAPPDATA%\\2345Explorer\\User Data\\Default\\Cache"
nameBrowser2345Code:.asciz "2345 Explorer Code Cache"
pathBrowser2345Code:.asciz "%LOCALAPPDATA%\\2345Explorer\\User Data\\Default\\Code Cache"
nameBrowser2345Gpu:.asciz "2345 Explorer GPUCache"
pathBrowser2345Gpu:.asciz "%LOCALAPPDATA%\\2345Explorer\\User Data\\Default\\GPUCache"
nameLiebaoCache:   .asciz "Liebao Browser Cache"
pathLiebaoCache:   .asciz "%LOCALAPPDATA%\\liebao\\User Data\\Default\\Cache"
nameLiebaoCode:    .asciz "Liebao Browser Code Cache"
pathLiebaoCode:    .asciz "%LOCALAPPDATA%\\liebao\\User Data\\Default\\Code Cache"
nameUCWebCache:    .asciz "UC Browser Cache"
pathUCWebCache:    .asciz "%LOCALAPPDATA%\\UCBrowser\\User Data\\Default\\Cache"
nameUCWebCode:     .asciz "UC Browser Code Cache"
pathUCWebCode:     .asciz "%LOCALAPPDATA%\\UCBrowser\\User Data\\Default\\Code Cache"
nameQuarkBrowserCache:.asciz "Quark Browser Cache"
pathQuarkBrowserCache:.asciz "%LOCALAPPDATA%\\Quark\\User Data\\Default\\Cache"
nameQuarkBrowserCode:.asciz "Quark Browser Code Cache"
pathQuarkBrowserCode:.asciz "%LOCALAPPDATA%\\Quark\\User Data\\Default\\Code Cache"
nameQuarkBrowserGpu:.asciz "Quark Browser GPUCache"
pathQuarkBrowserGpu:.asciz "%LOCALAPPDATA%\\Quark\\User Data\\Default\\GPUCache"
nameBaiduBrowserCache:.asciz "Baidu Browser Cache"
pathBaiduBrowserCache:.asciz "%LOCALAPPDATA%\\Baidu\\BaiduBrowser\\User Data\\Default\\Cache"
nameBaiduBrowserCode:.asciz "Baidu Browser Code Cache"
pathBaiduBrowserCode:.asciz "%LOCALAPPDATA%\\Baidu\\BaiduBrowser\\User Data\\Default\\Code Cache"
nameBaiduBrowserGpu:.asciz "Baidu Browser GPUCache"
pathBaiduBrowserGpu:.asciz "%LOCALAPPDATA%\\Baidu\\BaiduBrowser\\User Data\\Default\\GPUCache"
nameWhaleCache:    .asciz "Naver Whale Cache"
pathWhaleCache:    .asciz "%LOCALAPPDATA%\\Naver\\Naver Whale\\User Data\\Default\\Cache"
nameWhaleCode:     .asciz "Naver Whale Code Cache"
pathWhaleCode:     .asciz "%LOCALAPPDATA%\\Naver\\Naver Whale\\User Data\\Default\\Code Cache"
nameWhaleGpu:      .asciz "Naver Whale GPUCache"
pathWhaleGpu:      .asciz "%LOCALAPPDATA%\\Naver\\Naver Whale\\User Data\\Default\\GPUCache"
nameVivaldiCache:  .asciz "Vivaldi 缓存"
pathVivaldiCache:  .asciz "%LOCALAPPDATA%\\Vivaldi\\User Data\\Default\\Cache"
nameVivaldiCode:   .asciz "Vivaldi 代码缓存"
pathVivaldiCode:   .asciz "%LOCALAPPDATA%\\Vivaldi\\User Data\\Default\\Code Cache"
nameVivaldiGpu:    .asciz "Vivaldi GPU 缓存"
pathVivaldiGpu:    .asciz "%LOCALAPPDATA%\\Vivaldi\\User Data\\Default\\GPUCache"
nameVivaldiP1Cache:.asciz "Vivaldi Profile 1 Cache"
pathVivaldiP1Cache:.asciz "%LOCALAPPDATA%\\Vivaldi\\User Data\\Profile 1\\Cache"
nameVivaldiP1Code: .asciz "Vivaldi Profile 1 Code Cache"
pathVivaldiP1Code: .asciz "%LOCALAPPDATA%\\Vivaldi\\User Data\\Profile 1\\Code Cache"
nameVivaldiP2Cache:.asciz "Vivaldi Profile 2 Cache"
pathVivaldiP2Cache:.asciz "%LOCALAPPDATA%\\Vivaldi\\User Data\\Profile 2\\Cache"
nameVivaldiP2Code: .asciz "Vivaldi Profile 2 Code Cache"
pathVivaldiP2Code: .asciz "%LOCALAPPDATA%\\Vivaldi\\User Data\\Profile 2\\Code Cache"
nameYandexCache:   .asciz "Yandex Browser 缓存"
pathYandexCache:   .asciz "%LOCALAPPDATA%\\Yandex\\YandexBrowser\\User Data\\Default\\Cache"
nameYandexCode:    .asciz "Yandex Browser 代码缓存"
pathYandexCode:    .asciz "%LOCALAPPDATA%\\Yandex\\YandexBrowser\\User Data\\Default\\Code Cache"
nameYandexGpu:     .asciz "Yandex Browser GPU 缓存"
pathYandexGpu:     .asciz "%LOCALAPPDATA%\\Yandex\\YandexBrowser\\User Data\\Default\\GPUCache"
nameCentCache:     .asciz "Cent Browser 缓存"
pathCentCache:     .asciz "%LOCALAPPDATA%\\CentBrowser\\User Data\\Default\\Cache"
nameArcCache:      .asciz "Arc Browser 缓存"
pathArcCache:      .asciz "%LOCALAPPDATA%\\Packages\\TheBrowserCompany.Arc_ttt1ap7aakyb4\\LocalCache\\Local\\Arc\\User Data\\Default\\Cache"
nameCocCocCache:   .asciz "CocCoc Browser 缓存"
pathCocCocCache:   .asciz "%LOCALAPPDATA%\\CocCoc\\Browser\\User Data\\Default\\Cache"
nameWaterfoxLocal: .asciz "Waterfox 本地缓存根目录"
pathWaterfoxLocal: .asciz "%LOCALAPPDATA%\\Waterfox\\Profiles"
nameLibreWolfLocal:.asciz "LibreWolf 本地缓存根目录"
pathLibreWolfLocal:.asciz "%LOCALAPPDATA%\\LibreWolf\\Profiles"

nameVscodeCache:   .asciz "VS Code 缓存"
pathVscodeCache:   .asciz "%APPDATA%\\Code\\Cache"
nameVscodeData:    .asciz "VS Code 缓存数据"
pathVscodeData:    .asciz "%APPDATA%\\Code\\CachedData"
nameVscodeGpu:     .asciz "VS Code GPU 缓存"
pathVscodeGpu:     .asciz "%APPDATA%\\Code\\GPUCache"
nameVscodeLogs:    .asciz "VS Code logs"
pathVscodeLogs:    .asciz "%APPDATA%\\Code\\logs"
nameVscodeCrashpad:.asciz "VS Code Crashpad"
pathVscodeCrashpad:.asciz "%APPDATA%\\Code\\Crashpad"
nameDiscordCache:  .asciz "Discord 缓存"
pathDiscordCache:  .asciz "%APPDATA%\\discord\\Cache"
nameDiscordCode:   .asciz "Discord 代码缓存"
pathDiscordCode:   .asciz "%APPDATA%\\discord\\Code Cache"
nameDiscordGpu:    .asciz "Discord GPU 缓存"
pathDiscordGpu:    .asciz "%APPDATA%\\discord\\GPUCache"
nameDiscordLogs:   .asciz "Discord logs"
pathDiscordLogs:   .asciz "%APPDATA%\\discord\\logs"
nameDiscordCrash:  .asciz "Discord Crashpad"
pathDiscordCrash:  .asciz "%APPDATA%\\discord\\Crashpad"
nameTeamsCache:    .asciz "Microsoft Teams 应用缓存"
pathTeamsCache:    .asciz "%LOCALAPPDATA%\\Packages\\MSTeams_8wekyb3d8bbwe\\LocalCache"
nameTeamsNewTemp:  .asciz "New Teams temp"
pathTeamsNewTemp:  .asciz "%LOCALAPPDATA%\\Packages\\MSTeams_8wekyb3d8bbwe\\TempState"
nameTeamsClassicCache:.asciz "Microsoft Teams classic Cache"
pathTeamsClassicCache:.asciz "%APPDATA%\\Microsoft\\Teams\\Cache"
nameTeamsClassicCode:.asciz "Microsoft Teams classic Code Cache"
pathTeamsClassicCode:.asciz "%APPDATA%\\Microsoft\\Teams\\Code Cache"
nameTeamsClassicGpu:.asciz "Microsoft Teams classic GPUCache"
pathTeamsClassicGpu:.asciz "%APPDATA%\\Microsoft\\Teams\\GPUCache"
nameTelegram:      .asciz "Telegram Desktop 用户数据缓存"
pathTelegram:      .asciz "%APPDATA%\\Telegram Desktop\\tdata\\user_data"
nameDingTalkCache: .asciz "钉钉缓存"
pathDingTalkCache: .asciz "%APPDATA%\\DingTalk"
nameFeishuCache:   .asciz "飞书缓存"
pathFeishuCache:   .asciz "%APPDATA%\\Feishu"
nameLarkCache:     .asciz "Lark 缓存"
pathLarkCache:     .asciz "%APPDATA%\\LarkShell"
nameWpsCache:      .asciz "WPS Office 缓存"
pathWpsCache:      .asciz "%APPDATA%\\kingsoft\\office6\\cache"
nameZoomCache:     .asciz "Zoom WebView 缓存"
pathZoomCache:     .asciz "%APPDATA%\\Zoom\\data\\WebviewCache"
nameZoomLogs:      .asciz "Zoom logs"
pathZoomLogs:      .asciz "%APPDATA%\\Zoom\\logs"
nameSkypeCache:    .asciz "Skype Desktop Cache"
pathSkypeCache:    .asciz "%APPDATA%\\Microsoft\\Skype for Desktop\\Cache"
nameSkypeCode:     .asciz "Skype Desktop Code Cache"
pathSkypeCode:     .asciz "%APPDATA%\\Microsoft\\Skype for Desktop\\Code Cache"
nameSkypeGpu:      .asciz "Skype Desktop GPUCache"
pathSkypeGpu:      .asciz "%APPDATA%\\Microsoft\\Skype for Desktop\\GPUCache"
nameLineCache:     .asciz "LINE Cache"
pathLineCache:     .asciz "%LOCALAPPDATA%\\LINE\\Data\\Cache"
nameViberCache:    .asciz "Viber Cache"
pathViberCache:    .asciz "%APPDATA%\\ViberPC\\Cache"
nameViberLogs:     .asciz "Viber logs"
pathViberLogs:     .asciz "%APPDATA%\\ViberPC\\Logs"
nameElementCache:  .asciz "Element Cache"
pathElementCache:  .asciz "%APPDATA%\\Element\\Cache"
nameElementCode:   .asciz "Element Code Cache"
pathElementCode:   .asciz "%APPDATA%\\Element\\Code Cache"
nameElementGpu:    .asciz "Element GPUCache"
pathElementGpu:    .asciz "%APPDATA%\\Element\\GPUCache"
nameMattermostCache:.asciz "Mattermost Cache"
pathMattermostCache:.asciz "%APPDATA%\\Mattermost\\Cache"
nameMattermostCode:.asciz "Mattermost Code Cache"
pathMattermostCode:.asciz "%APPDATA%\\Mattermost\\Code Cache"
nameMattermostGpu: .asciz "Mattermost GPUCache"
pathMattermostGpu: .asciz "%APPDATA%\\Mattermost\\GPUCache"
nameSpotifyCache:  .asciz "Spotify 缓存"
pathSpotifyCache:  .asciz "%LOCALAPPDATA%\\Spotify\\Data"
nameSlackCache:    .asciz "Slack 缓存"
pathSlackCache:    .asciz "%APPDATA%\\Slack\\Cache"
nameSlackCode:     .asciz "Slack 代码缓存"
pathSlackCode:     .asciz "%APPDATA%\\Slack\\Code Cache"
nameSlackGpu:      .asciz "Slack GPU 缓存"
pathSlackGpu:      .asciz "%APPDATA%\\Slack\\GPUCache"
nameSlackLogs:     .asciz "Slack logs"
pathSlackLogs:     .asciz "%APPDATA%\\Slack\\logs"
namePostmanCache:  .asciz "Postman 缓存"
pathPostmanCache:  .asciz "%APPDATA%\\Postman\\Cache"
namePostmanCode:   .asciz "Postman Code Cache"
pathPostmanCode:   .asciz "%APPDATA%\\Postman\\Code Cache"
namePostmanGpu:    .asciz "Postman GPUCache"
pathPostmanGpu:    .asciz "%APPDATA%\\Postman\\GPUCache"
namePostmanLogs:   .asciz "Postman logs"
pathPostmanLogs:   .asciz "%APPDATA%\\Postman\\logs"
nameNotionCache:   .asciz "Notion 缓存"
pathNotionCache:   .asciz "%APPDATA%\\Notion\\Cache"
nameNotionCode:    .asciz "Notion 代码缓存"
pathNotionCode:    .asciz "%APPDATA%\\Notion\\Code Cache"
nameNotionGpu:     .asciz "Notion GPUCache"
pathNotionGpu:     .asciz "%APPDATA%\\Notion\\GPUCache"
nameNotionLogs:    .asciz "Notion logs"
pathNotionLogs:    .asciz "%APPDATA%\\Notion\\logs"
nameFigmaCache:    .asciz "Figma 缓存"
pathFigmaCache:    .asciz "%APPDATA%\\Figma\\Cache"
nameFigmaCode:     .asciz "Figma 代码缓存"
pathFigmaCode:     .asciz "%APPDATA%\\Figma\\Code Cache"
nameFigmaGpu:      .asciz "Figma GPUCache"
pathFigmaGpu:      .asciz "%APPDATA%\\Figma\\GPUCache"
nameFigmaLogs:     .asciz "Figma logs"
pathFigmaLogs:     .asciz "%APPDATA%\\Figma\\logs"
nameObsidianCache: .asciz "Obsidian Cache"
pathObsidianCache: .asciz "%APPDATA%\\Obsidian\\Cache"
nameObsidianCode:  .asciz "Obsidian Code Cache"
pathObsidianCode:  .asciz "%APPDATA%\\Obsidian\\Code Cache"
nameObsidianGpu:   .asciz "Obsidian GPU 缓存"
pathObsidianGpu:   .asciz "%APPDATA%\\Obsidian\\GPUCache"
nameObsidianLogs:  .asciz "Obsidian logs"
pathObsidianLogs:  .asciz "%APPDATA%\\Obsidian\\logs"
nameWeComData:     .asciz "企业微信数据"
pathWeComData:     .asciz "%APPDATA%\\Tencent\\WeCom"
nameTencentMeeting:.asciz "腾讯会议数据"
pathTencentMeeting:.asciz "%APPDATA%\\Tencent\\WeMeet"
nameBaiduNetdisk:  .asciz "百度网盘数据"
pathBaiduNetdisk:  .asciz "%APPDATA%\\baidu\\BaiduNetdisk"
nameBaiduNetdiskCache:.asciz "百度网盘缓存"
pathBaiduNetdiskCache:.asciz "%APPDATA%\\baidu\\BaiduNetdisk\\Cache"
nameBaiduNetdiskLogs:.asciz "百度网盘日志"
pathBaiduNetdiskLogs:.asciz "%APPDATA%\\baidu\\BaiduNetdisk\\log"
nameThunderData:   .asciz "迅雷数据"
pathThunderData:   .asciz "%APPDATA%\\Thunder Network"
nameThunderCache:  .asciz "迅雷缓存"
pathThunderCache:  .asciz "%LOCALAPPDATA%\\Thunder Network\\Thunder\\Cache"
nameThunderLogs:   .asciz "迅雷日志"
pathThunderLogs:   .asciz "%APPDATA%\\Thunder Network\\Thunder\\log"
nameNeteaseMusic:  .asciz "网易云音乐缓存"
pathNeteaseMusic:  .asciz "%LOCALAPPDATA%\\Netease\\CloudMusic\\Cache"
nameNeteaseMusicLogs:.asciz "网易云音乐日志"
pathNeteaseMusicLogs:.asciz "%LOCALAPPDATA%\\Netease\\CloudMusic\\Logs"
nameGithubDesktopCache:.asciz "GitHub Desktop Cache"
pathGithubDesktopCache:.asciz "%APPDATA%\\GitHub Desktop\\Cache"
nameGithubDesktopCode:.asciz "GitHub Desktop Code Cache"
pathGithubDesktopCode:.asciz "%APPDATA%\\GitHub Desktop\\Code Cache"
nameGithubDesktopGpu:.asciz "GitHub Desktop GPUCache"
pathGithubDesktopGpu:.asciz "%APPDATA%\\GitHub Desktop\\GPUCache"
nameGithubDesktopLogs:.asciz "GitHub Desktop logs"
pathGithubDesktopLogs:.asciz "%APPDATA%\\GitHub Desktop\\logs"
nameApifoxCache:   .asciz "Apifox Cache"
pathApifoxCache:   .asciz "%APPDATA%\\Apifox\\Cache"
nameApifoxCode:    .asciz "Apifox Code Cache"
pathApifoxCode:    .asciz "%APPDATA%\\Apifox\\Code Cache"
nameApifoxGpu:     .asciz "Apifox GPUCache"
pathApifoxGpu:     .asciz "%APPDATA%\\Apifox\\GPUCache"
nameApifoxLogs:    .asciz "Apifox logs"
pathApifoxLogs:    .asciz "%APPDATA%\\Apifox\\logs"
nameClaudeCache:   .asciz "Claude Cache"
pathClaudeCache:   .asciz "%APPDATA%\\Claude\\Cache"
nameClaudeCode:    .asciz "Claude Code Cache"
pathClaudeCode:    .asciz "%APPDATA%\\Claude\\Code Cache"
nameClaudeGpu:     .asciz "Claude GPUCache"
pathClaudeGpu:     .asciz "%APPDATA%\\Claude\\GPUCache"
nameClaudeLogs:    .asciz "Claude logs"
pathClaudeLogs:    .asciz "%APPDATA%\\Claude\\logs"
nameChatGptCache:  .asciz "ChatGPT Cache"
pathChatGptCache:  .asciz "%APPDATA%\\ChatGPT\\Cache"
nameChatGptCode:   .asciz "ChatGPT Code Cache"
pathChatGptCode:   .asciz "%APPDATA%\\ChatGPT\\Code Cache"
nameChatGptGpu:    .asciz "ChatGPT GPUCache"
pathChatGptGpu:    .asciz "%APPDATA%\\ChatGPT\\GPUCache"
nameChatGptLogs:   .asciz "ChatGPT logs"
pathChatGptLogs:   .asciz "%APPDATA%\\ChatGPT\\logs"
namePerplexityCache:.asciz "Perplexity Cache"
pathPerplexityCache:.asciz "%APPDATA%\\Perplexity\\Cache"
namePerplexityCode:.asciz "Perplexity Code Cache"
pathPerplexityCode:.asciz "%APPDATA%\\Perplexity\\Code Cache"
namePerplexityGpu: .asciz "Perplexity GPUCache"
pathPerplexityGpu: .asciz "%APPDATA%\\Perplexity\\GPUCache"
nameSignalCache:   .asciz "Signal Cache"
pathSignalCache:   .asciz "%APPDATA%\\Signal\\Cache"
nameSignalCode:    .asciz "Signal Code Cache"
pathSignalCode:    .asciz "%APPDATA%\\Signal\\Code Cache"
nameSignalGpu:     .asciz "Signal GPU Cache"
pathSignalGpu:     .asciz "%APPDATA%\\Signal\\GPUCache"
nameWhatsAppStore: .asciz "WhatsApp Desktop LocalCache"
pathWhatsAppStore: .asciz "%LOCALAPPDATA%\\Packages\\5319275A.WhatsAppDesktop_cv1g1gvanyjgm\\LocalCache"
nameCanvaCache:    .asciz "Canva Cache"
pathCanvaCache:    .asciz "%APPDATA%\\Canva\\Cache"
nameCanvaCode:     .asciz "Canva Code Cache"
pathCanvaCode:     .asciz "%APPDATA%\\Canva\\Code Cache"
nameCanvaGpu:      .asciz "Canva GPUCache"
pathCanvaGpu:      .asciz "%APPDATA%\\Canva\\GPUCache"
nameCanvaLogs:     .asciz "Canva logs"
pathCanvaLogs:     .asciz "%APPDATA%\\Canva\\logs"
nameTyporaCache:   .asciz "Typora Cache"
pathTyporaCache:   .asciz "%APPDATA%\\Typora\\Cache"
nameTyporaGpu:     .asciz "Typora GPUCache"
pathTyporaGpu:     .asciz "%APPDATA%\\Typora\\GPUCache"
nameTyporaLogs:    .asciz "Typora logs"
pathTyporaLogs:    .asciz "%APPDATA%\\Typora\\logs"
nameMotrixCache:   .asciz "Motrix Cache"
pathMotrixCache:   .asciz "%APPDATA%\\Motrix\\Cache"
nameMotrixLogs:    .asciz "Motrix logs"
pathMotrixLogs:    .asciz "%APPDATA%\\Motrix\\logs"
nameDropboxCache:  .asciz "Dropbox cache"
pathDropboxCache:  .asciz "%LOCALAPPDATA%\\Dropbox\\Cache"
nameDropboxLogs:   .asciz "Dropbox logs"
pathDropboxLogs:   .asciz "%LOCALAPPDATA%\\Dropbox\\logs"
nameGoogleDriveCache:.asciz "Google DriveFS cache"
pathGoogleDriveCache:.asciz "%LOCALAPPDATA%\\Google\\DriveFS\\Cache"
nameGoogleDriveLogs:.asciz "Google DriveFS logs"
pathGoogleDriveLogs:.asciz "%LOCALAPPDATA%\\Google\\DriveFS\\Logs"
nameGoogleDriveCrash:.asciz "Google DriveFS Crashpad"
pathGoogleDriveCrash:.asciz "%LOCALAPPDATA%\\Google\\DriveFS\\Crashpad"
nameMegaCache:     .asciz "MEGAsync cache"
pathMegaCache:     .asciz "%LOCALAPPDATA%\\Mega Limited\\MEGAsync\\Cache"
nameMegaLogs:      .asciz "MEGAsync logs"
pathMegaLogs:      .asciz "%LOCALAPPDATA%\\Mega Limited\\MEGAsync\\logs"
nameBoxDriveCache: .asciz "Box Drive cache"
pathBoxDriveCache: .asciz "%LOCALAPPDATA%\\Box\\Box\\cache"
nameBoxDriveLogs:  .asciz "Box Drive logs"
pathBoxDriveLogs:  .asciz "%LOCALAPPDATA%\\Box\\Box\\logs"
nameSyncthingLogs: .asciz "Syncthing logs"
pathSyncthingLogs: .asciz "%LOCALAPPDATA%\\Syncthing\\log"
nameTianyiCloudCache:.asciz "Tianyi Cloud cache"
pathTianyiCloudCache:.asciz "%APPDATA%\\ecloud\\Cache"
nameTianyiCloudLogs:.asciz "Tianyi Cloud logs"
pathTianyiCloudLogs:.asciz "%APPDATA%\\ecloud\\logs"
nameCaiyunCache:   .asciz "China Mobile Cloud cache"
pathCaiyunCache:   .asciz "%APPDATA%\\和彩云\\Cache"
nameCaiyunLogs:    .asciz "China Mobile Cloud logs"
pathCaiyunLogs:    .asciz "%APPDATA%\\和彩云\\logs"
nameAliyunDriveCache:.asciz "Aliyun Drive Cache"
pathAliyunDriveCache:.asciz "%APPDATA%\\aDrive\\Cache"
nameAliyunDriveLogs:.asciz "Aliyun Drive logs"
pathAliyunDriveLogs:.asciz "%APPDATA%\\aDrive\\logs"
nameQuarkDriveCache:.asciz "Quark Drive Cache"
pathQuarkDriveCache:.asciz "%APPDATA%\\QuarkCloudDrive\\Cache"
nameQuarkDriveLogs:.asciz "Quark Drive logs"
pathQuarkDriveLogs:.asciz "%APPDATA%\\QuarkCloudDrive\\logs"
nameNutstoreLogs:  .asciz "Nutstore logs"
pathNutstoreLogs:  .asciz "%APPDATA%\\Nutstore\\logs"
nameNutstoreCache: .asciz "Nutstore cache"
pathNutstoreCache: .asciz "%LOCALAPPDATA%\\Nutstore\\cache"
nameIDMLogs:       .asciz "Internet Download Manager logs"
pathIDMLogs:       .asciz "%APPDATA%\\IDM\\Logs"
nameQBittorrentLogs:.asciz "qBittorrent logs"
pathQBittorrentLogs:.asciz "%LOCALAPPDATA%\\qBittorrent\\logs"
nameEverythingLogs:.asciz "Everything logs"
pathEverythingLogs:.asciz "%APPDATA%\\Everything\\Logs"
nameEverythingTemp:.asciz "Everything temp"
pathEverythingTemp:.asciz "%LOCALAPPDATA%\\Everything\\Temp"
nameToDeskLogs:    .asciz "ToDesk logs"
pathToDeskLogs:    .asciz "%APPDATA%\\ToDesk\\logs"
nameSunloginLogs:  .asciz "Sunlogin logs"
pathSunloginLogs:  .asciz "%APPDATA%\\Oray\\SunloginClient\\log"
nameSogouPyLogs:   .asciz "Sogou Pinyin logs"
pathSogouPyLogs:   .asciz "%APPDATA%\\SogouPY\\log"
nameSogouPyTemp:   .asciz "Sogou Pinyin temp"
pathSogouPyTemp:   .asciz "%LOCALAPPDATA%\\SogouPY\\Temp"
nameQQPinyinLogs:  .asciz "QQ Pinyin logs"
pathQQPinyinLogs:  .asciz "%APPDATA%\\Tencent\\QQPinyin\\log"
nameQQPinyinCache: .asciz "QQ Pinyin cache"
pathQQPinyinCache: .asciz "%LOCALAPPDATA%\\Tencent\\QQPinyin\\Cache"
nameDingTalkLocalCache:.asciz "DingTalk Local Cache"
pathDingTalkLocalCache:.asciz "%LOCALAPPDATA%\\DingTalk\\Cache"
nameDingTalkLogs:  .asciz "DingTalk logs"
pathDingTalkLogs:  .asciz "%APPDATA%\\DingTalk\\logs"
nameDingTalkCode:  .asciz "DingTalk Code Cache"
pathDingTalkCode:  .asciz "%APPDATA%\\DingTalk\\Code Cache"
nameDingTalkGpu:   .asciz "DingTalk GPUCache"
pathDingTalkGpu:   .asciz "%APPDATA%\\DingTalk\\GPUCache"
nameDingTalkCrash:.asciz "DingTalk Crashpad"
pathDingTalkCrash:.asciz "%APPDATA%\\DingTalk\\Crashpad"
nameFeishuLogs:    .asciz "Feishu logs"
pathFeishuLogs:    .asciz "%APPDATA%\\Feishu\\logs"
nameFeishuCode:    .asciz "Feishu Code Cache"
pathFeishuCode:    .asciz "%APPDATA%\\Feishu\\Code Cache"
nameFeishuGpu:     .asciz "Feishu GPUCache"
pathFeishuGpu:     .asciz "%APPDATA%\\Feishu\\GPUCache"
nameFeishuLocalCache:.asciz "Feishu Local Cache"
pathFeishuLocalCache:.asciz "%LOCALAPPDATA%\\Feishu\\Cache"
nameFeishuCrash:   .asciz "Feishu Crashpad"
pathFeishuCrash:   .asciz "%APPDATA%\\Feishu\\Crashpad"
nameLarkLogs:      .asciz "Lark logs"
pathLarkLogs:      .asciz "%APPDATA%\\LarkShell\\logs"
nameLarkCode:      .asciz "Lark Code Cache"
pathLarkCode:      .asciz "%APPDATA%\\LarkShell\\Code Cache"
nameLarkGpu:       .asciz "Lark GPUCache"
pathLarkGpu:       .asciz "%APPDATA%\\LarkShell\\GPUCache"
nameLarkCrash:     .asciz "Lark Crashpad"
pathLarkCrash:     .asciz "%APPDATA%\\LarkShell\\Crashpad"
nameWpsLogs:       .asciz "WPS Office logs"
pathWpsLogs:       .asciz "%APPDATA%\\kingsoft\\office6\\logs"
nameWpsTemp:       .asciz "WPS Office temp"
pathWpsTemp:       .asciz "%APPDATA%\\kingsoft\\office6\\temp"
nameWpsCloudCache: .asciz "WPS Cloud cache"
pathWpsCloudCache: .asciz "%LOCALAPPDATA%\\Kingsoft\\WPS Cloud Files\\cache"
nameWpsLocalCache: .asciz "WPS Office local cache"
pathWpsLocalCache: .asciz "%LOCALAPPDATA%\\Kingsoft\\WPS Office\\cache"
nameWpsCrash:      .asciz "WPS Office crash dumps"
pathWpsCrash:      .asciz "%LOCALAPPDATA%\\Kingsoft\\WPS Office\\CrashDump"
nameKingsoftPdfCache:.asciz "Kingsoft PDF Cache"
pathKingsoftPdfCache:.asciz "%APPDATA%\\Kingsoft\\Kingsoft PDF\\Cache"
nameTencentDocsCache:.asciz "Tencent Docs Cache"
pathTencentDocsCache:.asciz "%APPDATA%\\Tencent\\TencentDocs\\Cache"
nameTencentDocsLogs:.asciz "Tencent Docs logs"
pathTencentDocsLogs:.asciz "%APPDATA%\\Tencent\\TencentDocs\\logs"
nameTencentDocsGpu:.asciz "Tencent Docs GPUCache"
pathTencentDocsGpu:.asciz "%APPDATA%\\Tencent\\TencentDocs\\GPUCache"
nameTencentDocsCrash:.asciz "Tencent Docs Crashpad"
pathTencentDocsCrash:.asciz "%APPDATA%\\Tencent\\TencentDocs\\Crashpad"
nameBaiduNetdiskLocalCache:.asciz "Baidu Netdisk Local Cache"
pathBaiduNetdiskLocalCache:.asciz "%LOCALAPPDATA%\\baidu\\BaiduNetdisk\\Cache"
nameBaiduNetdiskCrash:.asciz "Baidu Netdisk crash"
pathBaiduNetdiskCrash:.asciz "%LOCALAPPDATA%\\baidu\\BaiduNetdisk\\Crash"
nameBaiduNetdiskGpu:.asciz "Baidu Netdisk GPUCache"
pathBaiduNetdiskGpu:.asciz "%APPDATA%\\baidu\\BaiduNetdisk\\GPUCache"
nameAliyunDriveLocalCache:.asciz "Aliyun Drive Local Cache"
pathAliyunDriveLocalCache:.asciz "%LOCALAPPDATA%\\aDrive\\Cache"
nameAliyunDriveLocalLogs:.asciz "Aliyun Drive Local logs"
pathAliyunDriveLocalLogs:.asciz "%LOCALAPPDATA%\\aDrive\\logs"
nameAliyunDriveGpu:.asciz "Aliyun Drive GPUCache"
pathAliyunDriveGpu:.asciz "%APPDATA%\\aDrive\\GPUCache"
nameAliyunDriveCode:.asciz "Aliyun Drive Code Cache"
pathAliyunDriveCode:.asciz "%APPDATA%\\aDrive\\Code Cache"
nameAliyunDriveCrash:.asciz "Aliyun Drive Crashpad"
pathAliyunDriveCrash:.asciz "%APPDATA%\\aDrive\\Crashpad"
nameQuarkDriveLocalCache:.asciz "Quark Drive Local Cache"
pathQuarkDriveLocalCache:.asciz "%LOCALAPPDATA%\\QuarkCloudDrive\\Cache"
nameQuarkDriveGpu:.asciz "Quark Drive GPUCache"
pathQuarkDriveGpu:.asciz "%APPDATA%\\QuarkCloudDrive\\GPUCache"
nameQuarkDriveCode:.asciz "Quark Drive Code Cache"
pathQuarkDriveCode:.asciz "%APPDATA%\\QuarkCloudDrive\\Code Cache"
nameQuarkDriveCrash:.asciz "Quark Drive Crashpad"
pathQuarkDriveCrash:.asciz "%APPDATA%\\QuarkCloudDrive\\Crashpad"
nameDrive115Cache: .asciz "115 Drive Cache"
pathDrive115Cache: .asciz "%APPDATA%\\115\\Cache"
nameDrive115Logs:  .asciz "115 Drive logs"
pathDrive115Logs:  .asciz "%APPDATA%\\115\\logs"
nameThunderProfilesCache:.asciz "Thunder Profiles Cache"
pathThunderProfilesCache:.asciz "%LOCALAPPDATA%\\Thunder Network\\Thunder\\Profiles\\Cache"
nameThunderTemp:   .asciz "Thunder temp"
pathThunderTemp:   .asciz "%LOCALAPPDATA%\\Thunder Network\\Thunder\\Temp"
nameThunderBrowserCache:.asciz "Thunder browser cache"
pathThunderBrowserCache:.asciz "%APPDATA%\\Thunder Network\\Thunder\\Browser\\Cache"
nameToDeskCache:   .asciz "ToDesk cache"
pathToDeskCache:   .asciz "%APPDATA%\\ToDesk\\Cache"
nameSunloginCache: .asciz "Sunlogin cache"
pathSunloginCache: .asciz "%APPDATA%\\Oray\\SunloginClient\\cache"
nameSunloginCrash: .asciz "Sunlogin crash"
pathSunloginCrash: .asciz "%APPDATA%\\Oray\\SunloginClient\\crash"
nameRustdeskCache: .asciz "RustDesk cache"
pathRustdeskCache: .asciz "%APPDATA%\\RustDesk\\cache"
nameRustdeskLogs:  .asciz "RustDesk logs"
pathRustdeskLogs:  .asciz "%APPDATA%\\RustDesk\\log"
nameParsecCache:   .asciz "Parsec cache"
pathParsecCache:   .asciz "%APPDATA%\\Parsec\\cache"
nameParsecLogs:    .asciz "Parsec logs"
pathParsecLogs:    .asciz "%APPDATA%\\Parsec\\log"
nameAnyDeskLogs:   .asciz "AnyDesk logs"
pathAnyDeskLogs:   .asciz "%APPDATA%\\AnyDesk\\ad.trace"
nameTeamViewerLogs:.asciz "TeamViewer logs"
pathTeamViewerLogs:.asciz "%APPDATA%\\TeamViewer\\Logs"
nameUToolsCache:   .asciz "uTools Cache"
pathUToolsCache:   .asciz "%APPDATA%\\uTools\\Cache"
nameUToolsCode:    .asciz "uTools Code Cache"
pathUToolsCode:    .asciz "%APPDATA%\\uTools\\Code Cache"
nameUToolsLogs:    .asciz "uTools logs"
pathUToolsLogs:    .asciz "%APPDATA%\\uTools\\logs"
nameSnipasteCache: .asciz "Snipaste cache"
pathSnipasteCache: .asciz "%APPDATA%\\Snipaste\\cache"
nameSnipasteLogs:  .asciz "Snipaste logs"
pathSnipasteLogs:  .asciz "%APPDATA%\\Snipaste\\logs"
namePicGoCache:    .asciz "PicGo Cache"
pathPicGoCache:    .asciz "%APPDATA%\\picgo\\Cache"
namePicGoLogs:     .asciz "PicGo logs"
pathPicGoLogs:     .asciz "%APPDATA%\\picgo\\logs"
nameClashWinLogs:  .asciz "Clash for Windows logs"
pathClashWinLogs:  .asciz "%USERPROFILE%\\.config\\clash\\logs"
nameClashVergeLogs:.asciz "Clash Verge logs"
pathClashVergeLogs:.asciz "%APPDATA%\\io.github.clash-verge-rev.clash-verge-rev\\logs"
nameClashVergeCache:.asciz "Clash Verge Cache"
pathClashVergeCache:.asciz "%APPDATA%\\io.github.clash-verge-rev.clash-verge-rev\\Cache"
nameV2rayNLogs:    .asciz "v2rayN logs"
pathV2rayNLogs:    .asciz "%APPDATA%\\v2rayN\\guiLogs"
nameNetchLogs:     .asciz "Netch logs"
pathNetchLogs:     .asciz "%APPDATA%\\Netch\\logs"
nameBaiduPinyinLogs:.asciz "Baidu Pinyin logs"
pathBaiduPinyinLogs:.asciz "%APPDATA%\\Baidu\\BaiduPinyin\\log"
nameBaiduPinyinTemp:.asciz "Baidu Pinyin temp"
pathBaiduPinyinTemp:.asciz "%LOCALAPPDATA%\\Baidu\\BaiduPinyin\\Temp"
nameIflyImeLogs:   .asciz "iFlyIME logs"
pathIflyImeLogs:   .asciz "%APPDATA%\\iFlyIME\\log"
nameIflyImeTemp:   .asciz "iFlyIME temp"
pathIflyImeTemp:   .asciz "%LOCALAPPDATA%\\iFlyIME\\Temp"
nameTencentLemonLogs:.asciz "Tencent Lemon logs"
pathTencentLemonLogs:.asciz "%APPDATA%\\Tencent\\Lemon\\logs"
nameTencentLemonCache:.asciz "Tencent Lemon cache"
pathTencentLemonCache:.asciz "%LOCALAPPDATA%\\Tencent\\Lemon\\cache"
nameHuorongLogs:   .asciz "Huorong logs"
pathHuorongLogs:   .asciz "%PROGRAMDATA%\\Huorong\\Sysdiag\\log"
nameHuorongTemp:   .asciz "Huorong temp"
pathHuorongTemp:   .asciz "%PROGRAMDATA%\\Huorong\\Sysdiag\\temp"
nameZip360Cache:   .asciz "360 Zip Cache"
pathZip360Cache:   .asciz "%APPDATA%\\360zip\\Cache"
nameZip360Temp:    .asciz "360 Zip temp"
pathZip360Temp:    .asciz "%APPDATA%\\360zip\\Temp"
nameTencentPcMgrLogs:.asciz "Tencent PC Manager logs"
pathTencentPcMgrLogs:.asciz "%PROGRAMDATA%\\Tencent\\QQPCMgr\\Log"
nameTencentPcMgrCache:.asciz "Tencent PC Manager cache"
pathTencentPcMgrCache:.asciz "%LOCALAPPDATA%\\Tencent\\QQPCMgr\\Cache"
nameTencentPcMgrTemp:.asciz "Tencent PC Manager temp"
pathTencentPcMgrTemp:.asciz "%LOCALAPPDATA%\\Tencent\\QQPCMgr\\Temp"
nameSecurity360Logs:.asciz "360 Security logs"
pathSecurity360Logs:.asciz "%PROGRAMDATA%\\360Safe\\logs"
nameSecurity360Cache:.asciz "360 Security cache"
pathSecurity360Cache:.asciz "%PROGRAMDATA%\\360Safe\\Cache"
nameSecurity360Temp:.asciz "360 Security temp"
pathSecurity360Temp:.asciz "%PROGRAMDATA%\\360Safe\\Temp"
nameSecurity360sdLogs:.asciz "360 Antivirus logs"
pathSecurity360sdLogs:.asciz "%PROGRAMDATA%\\360sd\\log"
nameSecurity360sdCache:.asciz "360 Antivirus cache"
pathSecurity360sdCache:.asciz "%PROGRAMDATA%\\360sd\\Cache"
nameSecurity360Downloads:.asciz "360 Security downloads"
pathSecurity360Downloads:.asciz "%PROGRAMDATA%\\360Safe\\SoftMgr\\download"
nameLudashiLogs:   .asciz "LuDaShi logs"
pathLudashiLogs:   .asciz "%APPDATA%\\LuDaShi\\log"
nameLudashiCache:  .asciz "LuDaShi cache"
pathLudashiCache:  .asciz "%APPDATA%\\LuDaShi\\cache"
nameLudashiTemp:   .asciz "LuDaShi temp"
pathLudashiTemp:   .asciz "%LOCALAPPDATA%\\LuDaShi\\Temp"
nameDriverGeniusLogs:.asciz "DriverGenius logs"
pathDriverGeniusLogs:.asciz "%APPDATA%\\DriverGenius\\logs"
nameDriverGeniusCache:.asciz "DriverGenius cache"
pathDriverGeniusCache:.asciz "%APPDATA%\\DriverGenius\\Cache"
nameDriverBoosterCNCache:.asciz "DriverBooster CN cache"
pathDriverBoosterCNCache:.asciz "%PROGRAMDATA%\\IObit\\Driver Booster\\Download"
nameLenovoPcMgrLogs:.asciz "Lenovo PC Manager logs"
pathLenovoPcMgrLogs:.asciz "%LOCALAPPDATA%\\Lenovo\\PCManager\\log"
nameLenovoPcMgrCache:.asciz "Lenovo PC Manager cache"
pathLenovoPcMgrCache:.asciz "%LOCALAPPDATA%\\Lenovo\\PCManager\\cache"
nameHuaweiPcMgrLogs:.asciz "Huawei PC Manager logs"
pathHuaweiPcMgrLogs:.asciz "%LOCALAPPDATA%\\Huawei\\PCManager\\log"
nameHuaweiPcMgrCache:.asciz "Huawei PC Manager cache"
pathHuaweiPcMgrCache:.asciz "%LOCALAPPDATA%\\Huawei\\PCManager\\cache"
nameXiaomiPcSuiteCache:.asciz "Xiaomi PC Suite cache"
pathXiaomiPcSuiteCache:.asciz "%APPDATA%\\Xiaomi\\MiPhoneManager\\Cache"
nameXiaomiPcSuiteLogs:.asciz "Xiaomi PC Suite logs"
pathXiaomiPcSuiteLogs:.asciz "%APPDATA%\\Xiaomi\\MiPhoneManager\\Logs"
nameHuaweiMobileAssistantCache:.asciz "Huawei Mobile Assistant cache"
pathHuaweiMobileAssistantCache:.asciz "%APPDATA%\\Huawei\\HiSuite\\Cache"
nameHuaweiMobileAssistantLogs:.asciz "Huawei Mobile Assistant logs"
pathHuaweiMobileAssistantLogs:.asciz "%APPDATA%\\Huawei\\HiSuite\\log"
nameYoudaoDictCache:.asciz "Youdao Dict cache"
pathYoudaoDictCache:.asciz "%APPDATA%\\Youdao\\Dict\\Cache"
nameYoudaoDictLogs:.asciz "Youdao Dict logs"
pathYoudaoDictLogs:.asciz "%APPDATA%\\Youdao\\Dict\\logs"
nameYoudaoNoteCache:.asciz "Youdao Note cache"
pathYoudaoNoteCache:.asciz "%APPDATA%\\Youdao\\YNote\\Cache"
nameYoudaoNoteLogs:.asciz "Youdao Note logs"
pathYoudaoNoteLogs:.asciz "%APPDATA%\\Youdao\\YNote\\logs"
nameYinxiangCache: .asciz "Yinxiang Biji cache"
pathYinxiangCache: .asciz "%APPDATA%\\Yinxiang Biji\\Cache"
nameYinxiangLogs:  .asciz "Yinxiang Biji logs"
pathYinxiangLogs:  .asciz "%APPDATA%\\Yinxiang Biji\\Logs"
nameBaiduHiCache:  .asciz "Baidu Hi cache"
pathBaiduHiCache:  .asciz "%APPDATA%\\Baidu\\BaiduHi\\Cache"
nameBaiduHiLogs:   .asciz "Baidu Hi logs"
pathBaiduHiLogs:   .asciz "%APPDATA%\\Baidu\\BaiduHi\\logs"
nameQianniuCache:  .asciz "Qianniu cache"
pathQianniuCache:  .asciz "%APPDATA%\\AliWorkbench\\Cache"
nameQianniuLogs:   .asciz "Qianniu logs"
pathQianniuLogs:   .asciz "%APPDATA%\\AliWorkbench\\logs"
nameYuqueCache:    .asciz "Yuque cache"
pathYuqueCache:    .asciz "%APPDATA%\\Yuque\\Cache"
nameYuqueLogs:     .asciz "Yuque logs"
pathYuqueLogs:     .asciz "%APPDATA%\\Yuque\\logs"
nameXMindCNCache:  .asciz "XMind cache"
pathXMindCNCache:  .asciz "%APPDATA%\\XMind\\Cache"
nameXMindCNLogs:   .asciz "XMind logs"
pathXMindCNLogs:   .asciz "%APPDATA%\\XMind\\logs"
nameFoxmailCache:  .asciz "Foxmail cache"
pathFoxmailCache:  .asciz "%APPDATA%\\Tencent\\Foxmail\\Cache"
nameFoxmailLogs:   .asciz "Foxmail logs"
pathFoxmailLogs:   .asciz "%APPDATA%\\Tencent\\Foxmail\\logs"
nameAliWangwangCache:.asciz "AliWangwang cache"
pathAliWangwangCache:.asciz "%APPDATA%\\AliWangwang\\Cache"
nameAliWangwangLogs:.asciz "AliWangwang logs"
pathAliWangwangLogs:.asciz "%APPDATA%\\AliWangwang\\logs"
nameClassInCache:  .asciz "ClassIn cache"
pathClassInCache:  .asciz "%APPDATA%\\ClassIn\\Cache"
nameClassInLogs:   .asciz "ClassIn logs"
pathClassInLogs:   .asciz "%APPDATA%\\ClassIn\\logs"
nameTencentClassroomCache:.asciz "Tencent Classroom cache"
pathTencentClassroomCache:.asciz "%APPDATA%\\Tencent\\TXEDU\\Cache"
nameTencentClassroomLogs:.asciz "Tencent Classroom logs"
pathTencentClassroomLogs:.asciz "%APPDATA%\\Tencent\\TXEDU\\logs"
nameChaoxingCache: .asciz "Chaoxing cache"
pathChaoxingCache: .asciz "%APPDATA%\\Chaoxing\\Cache"
nameChaoxingLogs:  .asciz "Chaoxing logs"
pathChaoxingLogs:  .asciz "%APPDATA%\\Chaoxing\\logs"
nameSeewoCache:    .asciz "Seewo cache"
pathSeewoCache:    .asciz "%APPDATA%\\Seewo\\Cache"
nameSeewoLogs:     .asciz "Seewo logs"
pathSeewoLogs:     .asciz "%APPDATA%\\Seewo\\logs"
nameYoudaoCourseCache:.asciz "Youdao Course cache"
pathYoudaoCourseCache:.asciz "%APPDATA%\\Youdao\\Course\\Cache"
nameYoudaoCourseLogs:.asciz "Youdao Course logs"
pathYoudaoCourseLogs:.asciz "%APPDATA%\\Youdao\\Course\\logs"
nameLanhuCache:    .asciz "Lanhu cache"
pathLanhuCache:    .asciz "%APPDATA%\\Lanhu\\Cache"
nameLanhuLogs:     .asciz "Lanhu logs"
pathLanhuLogs:     .asciz "%APPDATA%\\Lanhu\\logs"
namePixsoCache:    .asciz "Pixso cache"
pathPixsoCache:    .asciz "%APPDATA%\\Pixso\\Cache"
namePixsoCode:     .asciz "Pixso Code Cache"
pathPixsoCode:     .asciz "%APPDATA%\\Pixso\\Code Cache"
nameMasterGoCache: .asciz "MasterGo cache"
pathMasterGoCache: .asciz "%APPDATA%\\MasterGo\\Cache"
nameMasterGoCode:  .asciz "MasterGo Code Cache"
pathMasterGoCode:  .asciz "%APPDATA%\\MasterGo\\Code Cache"
nameEastMoneyCache:.asciz "EastMoney cache"
pathEastMoneyCache:.asciz "%APPDATA%\\EastMoney\\Cache"
nameEastMoneyLogs: .asciz "EastMoney logs"
pathEastMoneyLogs: .asciz "%APPDATA%\\EastMoney\\logs"
nameTongHuaShunCache:.asciz "TongHuaShun cache"
pathTongHuaShunCache:.asciz "%APPDATA%\\10jqka\\Cache"
nameTongHuaShunLogs:.asciz "TongHuaShun logs"
pathTongHuaShunLogs:.asciz "%APPDATA%\\10jqka\\logs"
nameTencentYuanbaoCache:.asciz "Tencent Yuanbao Cache"
pathTencentYuanbaoCache:.asciz "%APPDATA%\\Tencent\\Yuanbao\\Cache"
nameTencentYuanbaoCode:.asciz "Tencent Yuanbao Code Cache"
pathTencentYuanbaoCode:.asciz "%APPDATA%\\Tencent\\Yuanbao\\Code Cache"
nameTencentYuanbaoGpu:.asciz "Tencent Yuanbao GPUCache"
pathTencentYuanbaoGpu:.asciz "%APPDATA%\\Tencent\\Yuanbao\\GPUCache"
nameTencentYuanbaoLogs:.asciz "Tencent Yuanbao logs"
pathTencentYuanbaoLogs:.asciz "%APPDATA%\\Tencent\\Yuanbao\\logs"
nameKimiCache:     .asciz "Kimi Cache"
pathKimiCache:     .asciz "%APPDATA%\\Kimi\\Cache"
nameKimiCode:      .asciz "Kimi Code Cache"
pathKimiCode:      .asciz "%APPDATA%\\Kimi\\Code Cache"
nameKimiGpu:       .asciz "Kimi GPUCache"
pathKimiGpu:       .asciz "%APPDATA%\\Kimi\\GPUCache"
nameKimiLogs:      .asciz "Kimi logs"
pathKimiLogs:      .asciz "%APPDATA%\\Kimi\\logs"
nameBaiduComateCache:.asciz "Baidu Comate Cache"
pathBaiduComateCache:.asciz "%APPDATA%\\Baidu\\Comate\\Cache"
nameBaiduComateLogs:.asciz "Baidu Comate logs"
pathBaiduComateLogs:.asciz "%APPDATA%\\Baidu\\Comate\\logs"
nameEdrawMaxCache: .asciz "EdrawMax Cache"
pathEdrawMaxCache: .asciz "%APPDATA%\\EdrawMax\\Cache"
nameEdrawMaxLogs:  .asciz "EdrawMax logs"
pathEdrawMaxLogs:  .asciz "%APPDATA%\\EdrawMax\\logs"
nameMindMasterCache:.asciz "MindMaster Cache"
pathMindMasterCache:.asciz "%APPDATA%\\MindMaster\\Cache"
nameMindMasterLogs:.asciz "MindMaster logs"
pathMindMasterLogs:.asciz "%APPDATA%\\MindMaster\\logs"
nameMubuCache:     .asciz "Mubu Cache"
pathMubuCache:     .asciz "%APPDATA%\\Mubu\\Cache"
nameMubuLogs:      .asciz "Mubu logs"
pathMubuLogs:      .asciz "%APPDATA%\\Mubu\\logs"
nameNeteaseMailCache:.asciz "NetEase MailMaster Cache"
pathNeteaseMailCache:.asciz "%APPDATA%\\Netease\\MailMaster\\Cache"
nameNeteaseMailLogs:.asciz "NetEase MailMaster logs"
pathNeteaseMailLogs:.asciz "%APPDATA%\\Netease\\MailMaster\\logs"
nameYoudaoTranslateCache:.asciz "Youdao Translate Cache"
pathYoudaoTranslateCache:.asciz "%APPDATA%\\Youdao\\YoudaoTranslate\\Cache"
nameYoudaoTranslateLogs:.asciz "Youdao Translate logs"
pathYoudaoTranslateLogs:.asciz "%APPDATA%\\Youdao\\YoudaoTranslate\\logs"
nameTickTickCache: .asciz "TickTick Cache"
pathTickTickCache: .asciz "%APPDATA%\\TickTick\\Cache"
nameTickTickLogs:  .asciz "TickTick logs"
pathTickTickLogs:  .asciz "%APPDATA%\\TickTick\\logs"
nameJoplinCache:   .asciz "Joplin Cache"
pathJoplinCache:   .asciz "%APPDATA%\\Joplin\\Cache"
nameJoplinLogs:    .asciz "Joplin logs"
pathJoplinLogs:    .asciz "%APPDATA%\\Joplin\\logs"
nameZoteroCache:   .asciz "Zotero cache"
pathZoteroCache:   .asciz "%LOCALAPPDATA%\\Zotero\\Zotero\\Profiles"
nameEvernoteCache: .asciz "Evernote cache"
pathEvernoteCache: .asciz "%APPDATA%\\Evernote\\Cache"
nameEvernoteLogs:  .asciz "Evernote logs"
pathEvernoteLogs:  .asciz "%APPDATA%\\Evernote\\logs"
nameAdobeCcCache:  .asciz "Adobe Creative Cloud cache"
pathAdobeCcCache:  .asciz "%LOCALAPPDATA%\\Adobe\\Creative Cloud Libraries\\Caches"
nameAdobeCcLogs:   .asciz "Adobe Creative Cloud logs"
pathAdobeCcLogs:   .asciz "%LOCALAPPDATA%\\Adobe\\Creative Cloud\\Logs"
nameThunderbirdCache:.asciz "Thunderbird cache"
pathThunderbirdCache:.asciz "%LOCALAPPDATA%\\Thunderbird\\Profiles"
nameThunderbirdLogs:.asciz "Thunderbird crash reports"
pathThunderbirdLogs:.asciz "%APPDATA%\\Thunderbird\\Crash Reports"
nameMailspringCache:.asciz "Mailspring Cache"
pathMailspringCache:.asciz "%APPDATA%\\Mailspring\\Cache"
nameMailspringLogs:.asciz "Mailspring logs"
pathMailspringLogs:.asciz "%APPDATA%\\Mailspring\\logs"
nameTodoistCache:  .asciz "Todoist Cache"
pathTodoistCache:  .asciz "%APPDATA%\\Todoist\\Cache"
nameTodoistCode:   .asciz "Todoist Code Cache"
pathTodoistCode:   .asciz "%APPDATA%\\Todoist\\Code Cache"
nameTodoistLogs:   .asciz "Todoist logs"
pathTodoistLogs:   .asciz "%APPDATA%\\Todoist\\logs"
nameTrelloCache:   .asciz "Trello Cache"
pathTrelloCache:   .asciz "%APPDATA%\\Trello\\Cache"
nameTrelloCode:    .asciz "Trello Code Cache"
pathTrelloCode:    .asciz "%APPDATA%\\Trello\\Code Cache"
nameMiroCache:     .asciz "Miro Cache"
pathMiroCache:     .asciz "%APPDATA%\\Miro\\Cache"
nameMiroCode:      .asciz "Miro Code Cache"
pathMiroCode:      .asciz "%APPDATA%\\Miro\\Code Cache"
nameLinearCache:   .asciz "Linear Cache"
pathLinearCache:   .asciz "%APPDATA%\\Linear\\Cache"
nameLinearCode:    .asciz "Linear Code Cache"
pathLinearCode:    .asciz "%APPDATA%\\Linear\\Code Cache"

nameWeChatFiles:   .asciz "微信文档聊天数据根目录"
pathWeChatFiles:   .asciz "%USERPROFILE%\\Documents\\WeChat Files"
nameTencentFiles:  .asciz "QQ 文档聊天数据根目录"
pathTencentFiles:  .asciz "%USERPROFILE%\\Documents\\Tencent Files"
nameQQEimFiles:    .asciz "QQEIM 文档聊天数据根目录"
pathQQEimFiles:    .asciz "%USERPROFILE%\\Documents\\QQEIM Files"
nameWeChatAppData: .asciz "微信 AppData 数据"
pathWeChatAppData: .asciz "%APPDATA%\\Tencent\\WeChat"
nameQQAppData:     .asciz "QQ AppData 数据"
pathQQAppData:     .asciz "%APPDATA%\\Tencent\\QQ"
nameQQNTData:      .asciz "QQNT 数据"
pathQQNTData:      .asciz "%APPDATA%\\Tencent\\QQNT"
nameWeChatLogs:    .asciz "WeChat logs"
pathWeChatLogs:    .asciz "%APPDATA%\\Tencent\\WeChat\\log"
nameWeChatXPluginLogs:.asciz "WeChat XPlugin logs"
pathWeChatXPluginLogs:.asciz "%APPDATA%\\Tencent\\WeChat\\XPlugin\\Logs"
nameWeChatCefCache:.asciz "WeChat CefCache"
pathWeChatCefCache:.asciz "%APPDATA%\\Tencent\\WeChat\\CefCache"
nameQQNTCache:     .asciz "QQNT Cache"
pathQQNTCache:     .asciz "%APPDATA%\\Tencent\\QQNT\\Cache"
nameQQNTGpu:       .asciz "QQNT GPUCache"
pathQQNTGpu:       .asciz "%APPDATA%\\Tencent\\QQNT\\GPUCache"
nameQQNTLogs:      .asciz "QQNT logs"
pathQQNTLogs:      .asciz "%APPDATA%\\Tencent\\QQNT\\logs"
nameQQNTCrashpad:  .asciz "QQNT Crashpad"
pathQQNTCrashpad:  .asciz "%APPDATA%\\Tencent\\QQNT\\Crashpad"
nameTIMLogs:       .asciz "TIM logs"
pathTIMLogs:       .asciz "%APPDATA%\\Tencent\\TIM\\log"
nameTIMCache:      .asciz "TIM cache"
pathTIMCache:      .asciz "%APPDATA%\\Tencent\\TIM\\Cache"
nameQQGuildCache:  .asciz "QQGuild Cache"
pathQQGuildCache:  .asciz "%APPDATA%\\Tencent\\QQGuild\\Cache"
nameQQGuildLogs:   .asciz "QQGuild logs"
pathQQGuildLogs:   .asciz "%APPDATA%\\Tencent\\QQGuild\\logs"
nameWeComCache:    .asciz "WeCom cache"
pathWeComCache:    .asciz "%APPDATA%\\Tencent\\WeCom\\Cache"
nameWeComLogs:     .asciz "WeCom logs"
pathWeComLogs:     .asciz "%APPDATA%\\Tencent\\WeCom\\Log"
nameWeComGpu:      .asciz "WeCom GPUCache"
pathWeComGpu:      .asciz "%APPDATA%\\Tencent\\WeCom\\GPUCache"
nameWeComCrash:    .asciz "WeCom Crashpad"
pathWeComCrash:    .asciz "%APPDATA%\\Tencent\\WeCom\\Crashpad"
nameTencentMeetingLogs:.asciz "Tencent Meeting logs"
pathTencentMeetingLogs:.asciz "%APPDATA%\\Tencent\\WeMeet\\Logs"
nameTencentMeetingCache:.asciz "Tencent Meeting cache"
pathTencentMeetingCache:.asciz "%LOCALAPPDATA%\\Tencent\\WeMeet\\Cache"
nameTencentMeetingGpu:.asciz "Tencent Meeting GPUCache"
pathTencentMeetingGpu:.asciz "%APPDATA%\\Tencent\\WeMeet\\GPUCache"
nameTencentMeetingCrash:.asciz "Tencent Meeting Crashpad"
pathTencentMeetingCrash:.asciz "%APPDATA%\\Tencent\\WeMeet\\Crashpad"
nameWeChatDevToolsCache:.asciz "WeChat DevTools cache"
pathWeChatDevToolsCache:.asciz "%APPDATA%\\Tencent\\微信开发者工具\\Cache"
nameWeChatDevToolsCode:.asciz "WeChat DevTools Code Cache"
pathWeChatDevToolsCode:.asciz "%APPDATA%\\Tencent\\微信开发者工具\\Code Cache"
nameWeChatDevToolsLogs:.asciz "WeChat DevTools logs"
pathWeChatDevToolsLogs:.asciz "%APPDATA%\\Tencent\\微信开发者工具\\logs"
nameWeChatDevToolsGpu:.asciz "WeChat DevTools GPUCache"
pathWeChatDevToolsGpu:.asciz "%APPDATA%\\Tencent\\微信开发者工具\\GPUCache"
nameHBuilderXCache:.asciz "HBuilderX cache"
pathHBuilderXCache:.asciz "%APPDATA%\\HBuilder X\\Cache"
nameHBuilderXCode:.asciz "HBuilderX Code Cache"
pathHBuilderXCode:.asciz "%APPDATA%\\HBuilder X\\Code Cache"
nameHBuilderXGpu:.asciz "HBuilderX GPUCache"
pathHBuilderXGpu:.asciz "%APPDATA%\\HBuilder X\\GPUCache"
nameHBuilderXLogs:.asciz "HBuilderX logs"
pathHBuilderXLogs:.asciz "%APPDATA%\\HBuilder X\\logs"
nameDevEcoCache:   .asciz "DevEco Studio cache"
pathDevEcoCache:   .asciz "%LOCALAPPDATA%\\Huawei\\DevEcoStudio"
nameDevEcoLogs:    .asciz "DevEco Studio logs"
pathDevEcoLogs:    .asciz "%APPDATA%\\Huawei\\DevEcoStudio\\logs"
nameTaroCache:     .asciz "Taro cache"
pathTaroCache:     .asciz "%USERPROFILE%\\.taro"
nameUniappCache:   .asciz "uni-app cache"
pathUniappCache:   .asciz "%USERPROFILE%\\.dcloud"

nameNpm:           .asciz "npm 缓存"
pathNpm:           .asciz "%APPDATA%\\npm-cache"
nameNpmLocal:      .asciz "npm local cache"
pathNpmLocal:      .asciz "%LOCALAPPDATA%\\npm-cache"
namePip:           .asciz "pip 缓存"
pathPip:           .asciz "%LOCALAPPDATA%\\pip\\Cache"
nameNuget:         .asciz "NuGet 包缓存"
pathNuget:         .asciz "%USERPROFILE%\\.nuget\\packages"
nameGradle:        .asciz "Gradle 缓存"
pathGradle:        .asciz "%USERPROFILE%\\.gradle\\caches"
nameGradleWrapper: .asciz "Gradle wrapper 分发缓存"
pathGradleWrapper: .asciz "%USERPROFILE%\\.gradle\\wrapper\\dists"
nameGradleDaemon:  .asciz "Gradle daemon 日志"
pathGradleDaemon:  .asciz "%USERPROFILE%\\.gradle\\daemon"
nameGradleNative:  .asciz "Gradle native 缓存"
pathGradleNative:  .asciz "%USERPROFILE%\\.gradle\\native"
nameGradleBuildOutput:.asciz "Gradle buildOutputCleanup"
pathGradleBuildOutput:.asciz "%USERPROFILE%\\.gradle\\buildOutputCleanup"
nameFabricLoom:    .asciz "Fabric Loom 缓存"
pathFabricLoom:    .asciz "%USERPROFILE%\\.gradle\\caches\\fabric-loom"
nameFabricMinecraft:.asciz "Fabric Loom Minecraft 缓存"
pathFabricMinecraft:.asciz "%USERPROFILE%\\.gradle\\caches\\minecraft"
nameForgeGradle:   .asciz "ForgeGradle 缓存"
pathForgeGradle:   .asciz "%USERPROFILE%\\.gradle\\caches\\forge_gradle"
nameNeoForgeGradle:.asciz "NeoForge Gradle 缓存"
pathNeoForgeGradle:.asciz "%USERPROFILE%\\.gradle\\caches\\net.neoforged.gradle"
nameQuiltLoom:     .asciz "Quilt Loom 缓存"
pathQuiltLoom:     .asciz "%USERPROFILE%\\.gradle\\caches\\quilt-loom"
nameArchitecturyLoom:.asciz "Architectury Loom 缓存"
pathArchitecturyLoom:.asciz "%USERPROFILE%\\.gradle\\caches\\architectury-loom"
namePaperweight:   .asciz "Paperweight 缓存"
pathPaperweight:   .asciz "%USERPROFILE%\\.gradle\\caches\\paperweight"
nameMcDevCache:    .asciz "MinecraftDev Gradle 缓存"
pathMcDevCache:    .asciz "%USERPROFILE%\\.gradle\\caches\\minecraftdev"
nameMaven:         .asciz "Maven 本地仓库"
pathMaven:         .asciz "%USERPROFILE%\\.m2\\repository"
nameMavenWrapper:  .asciz "Maven wrapper cache"
pathMavenWrapper:  .asciz "%USERPROFILE%\\.m2\\wrapper"
nameYarn:          .asciz "Yarn 缓存"
pathYarn:          .asciz "%LOCALAPPDATA%\\Yarn\\Cache"
nameYarnBerry:     .asciz "Yarn Berry cache"
pathYarnBerry:     .asciz "%LOCALAPPDATA%\\Yarn\\Berry"
namePnpm:          .asciz "pnpm store"
pathPnpm:          .asciz "%LOCALAPPDATA%\\pnpm\\store"
nameCargo:         .asciz "Cargo registry 缓存"
pathCargo:         .asciz "%USERPROFILE%\\.cargo\\registry"
nameGoBuild:       .asciz "Go build cache"
pathGoBuild:       .asciz "%LOCALAPPDATA%\\go-build"
nameDockerDesktop: .asciz "Docker Desktop 本地数据"
pathDockerDesktop: .asciz "%LOCALAPPDATA%\\Docker"
nameDockerDesktopLogs:.asciz "Docker Desktop logs"
pathDockerDesktopLogs:.asciz "%APPDATA%\\Docker Desktop\\logs"
namePoetryCache:   .asciz "Poetry 缓存"
pathPoetryCache:   .asciz "%LOCALAPPDATA%\\pypoetry\\Cache"
nameAndroidBuild:  .asciz "Android build cache"
pathAndroidBuild:  .asciz "%USERPROFILE%\\.android\\build-cache"
nameUvCache:       .asciz "uv 缓存"
pathUvCache:       .asciz "%LOCALAPPDATA%\\uv\\cache"
nameCondaPkgs:     .asciz "Conda pkgs 缓存"
pathCondaPkgs:     .asciz "%USERPROFILE%\\.conda\\pkgs"
nameHuggingFace:   .asciz "Hugging Face cache"
pathHuggingFace:   .asciz "%USERPROFILE%\\.cache\\huggingface"
nameCursorCache:   .asciz "Cursor 缓存"
pathCursorCache:   .asciz "%APPDATA%\\Cursor\\Cache"
nameCursorData:    .asciz "Cursor CachedData"
pathCursorData:    .asciz "%APPDATA%\\Cursor\\CachedData"
nameWindsurfCache: .asciz "Windsurf 缓存"
pathWindsurfCache: .asciz "%APPDATA%\\Windsurf\\Cache"
nameTraeCache:     .asciz "Trae 缓存"
pathTraeCache:     .asciz "%APPDATA%\\Trae\\Cache"
nameJetBrainsLocal:.asciz "JetBrains 本地缓存"
pathJetBrainsLocal:.asciz "%LOCALAPPDATA%\\JetBrains"
nameJetBrainsToolboxCache:.asciz "JetBrains Toolbox cache"
pathJetBrainsToolboxCache:.asciz "%LOCALAPPDATA%\\JetBrains\\Toolbox\\cache"
nameJetBrainsToolboxLogs:.asciz "JetBrains Toolbox logs"
pathJetBrainsToolboxLogs:.asciz "%LOCALAPPDATA%\\JetBrains\\Toolbox\\logs"
nameVsCache:       .asciz "Visual Studio 本地缓存"
pathVsCache:       .asciz "%LOCALAPPDATA%\\Microsoft\\VisualStudio"
nameVsCodeCachedData:.asciz "VS Code CachedData"
pathVsCodeCachedData:.asciz "%APPDATA%\\Code\\CachedData"
nameVsCodeUserLogs:.asciz "VS Code user logs"
pathVsCodeUserLogs:.asciz "%APPDATA%\\Code\\logs"
nameNodeGyp:       .asciz "node-gyp 缓存"
pathNodeGyp:       .asciz "%LOCALAPPDATA%\\node-gyp\\Cache"
nameElectronCache: .asciz "Electron 缓存"
pathElectronCache: .asciz "%LOCALAPPDATA%\\electron\\Cache"
namePlaywright:    .asciz "Playwright 浏览器缓存"
pathPlaywright:    .asciz "%LOCALAPPDATA%\\ms-playwright"
nameSelenium:      .asciz "Selenium Manager 缓存"
pathSelenium:      .asciz "%LOCALAPPDATA%\\selenium"
nameTorchCache:    .asciz "PyTorch cache"
pathTorchCache:    .asciz "%USERPROFILE%\\.cache\\torch"
namePreCommit:     .asciz "pre-commit cache"
pathPreCommit:     .asciz "%USERPROFILE%\\.cache\\pre-commit"
nameGoModCache:    .asciz "Go module download cache"
pathGoModCache:    .asciz "%USERPROFILE%\\go\\pkg\\mod\\cache"
nameRustGit:       .asciz "Cargo git cache"
pathRustGit:       .asciz "%USERPROFILE%\\.cargo\\git"
nameVcpkgDownloads:.asciz "vcpkg downloads"
pathVcpkgDownloads:.asciz "%LOCALAPPDATA%\\vcpkg\\downloads"
nameConanCache:    .asciz "Conan cache"
pathConanCache:    .asciz "%USERPROFILE%\\.conan2\\p"
nameComposerCache: .asciz "Composer cache"
pathComposerCache: .asciz "%LOCALAPPDATA%\\Composer\\files"
nameRubyGemCache:  .asciz "RubyGems cache"
pathRubyGemCache:  .asciz "%USERPROFILE%\\.gem\\specs"
namePubCache:      .asciz "Dart Pub cache"
pathPubCache:      .asciz "%LOCALAPPDATA%\\Pub\\Cache"
nameDotnetHttp:    .asciz ".NET HTTP cache"
pathDotnetHttp:    .asciz "%LOCALAPPDATA%\\NuGet\\v3-cache"
nameBunCache:      .asciz "Bun install cache"
pathBunCache:      .asciz "%USERPROFILE%\\.bun\\install\\cache"
nameDenoCache:     .asciz "Deno cache"
pathDenoCache:     .asciz "%LOCALAPPDATA%\\deno"
nameRuffCache:     .asciz "Ruff cache"
pathRuffCache:     .asciz "%USERPROFILE%\\.cache\\ruff"
nameMypyCache:     .asciz "mypy cache"
pathMypyCache:     .asciz "%USERPROFILE%\\.cache\\mypy"
nameCcache:        .asciz "ccache cache"
pathCcache:        .asciz "%USERPROFILE%\\.ccache"
nameNinjaCache:    .asciz "Ninja build logs"
pathNinjaCache:    .asciz "%LOCALAPPDATA%\\ninja"
nameGitKrakenCache:.asciz "GitKraken Cache"
pathGitKrakenCache:.asciz "%APPDATA%\\gitkraken\\Cache"
nameGitKrakenGpu:  .asciz "GitKraken GPUCache"
pathGitKrakenGpu:  .asciz "%APPDATA%\\gitkraken\\GPUCache"
nameInsomniaCache: .asciz "Insomnia Cache"
pathInsomniaCache: .asciz "%APPDATA%\\Insomnia\\Cache"
nameInsomniaCode:  .asciz "Insomnia Code Cache"
pathInsomniaCode:  .asciz "%APPDATA%\\Insomnia\\Code Cache"
nameInsomniaGpu:   .asciz "Insomnia GPUCache"
pathInsomniaGpu:   .asciz "%APPDATA%\\Insomnia\\GPUCache"
nameApiPostCache:  .asciz "ApiPost Cache"
pathApiPostCache:  .asciz "%APPDATA%\\ApiPost\\Cache"
nameApiPostCode:   .asciz "ApiPost Code Cache"
pathApiPostCode:   .asciz "%APPDATA%\\ApiPost\\Code Cache"
nameApiPostLogs:   .asciz "ApiPost logs"
pathApiPostLogs:   .asciz "%APPDATA%\\ApiPost\\logs"
nameSourceTreeCache:.asciz "SourceTree cache"
pathSourceTreeCache:.asciz "%LOCALAPPDATA%\\Atlassian\\SourceTree\\cache"
nameSourceTreeLogs:.asciz "SourceTree logs"
pathSourceTreeLogs:.asciz "%LOCALAPPDATA%\\Atlassian\\SourceTree\\sourcetree.log"
nameTortoiseGitLogs:.asciz "TortoiseGit logs"
pathTortoiseGitLogs:.asciz "%LOCALAPPDATA%\\TortoiseGit\\log"
nameCmderCache:    .asciz "Cmder cache"
pathCmderCache:    .asciz "%LOCALAPPDATA%\\cmder\\cache"
nameEmscriptenCache:.asciz "Emscripten cache"
pathEmscriptenCache:.asciz "%USERPROFILE%\\.emscripten_cache"
nameLmStudioCache: .asciz "LM Studio Cache"
pathLmStudioCache: .asciz "%APPDATA%\\LM Studio\\Cache"
nameLmStudioGpu:   .asciz "LM Studio GPUCache"
pathLmStudioGpu:   .asciz "%APPDATA%\\LM Studio\\GPUCache"
nameOllamaLogs:    .asciz "Ollama logs"
pathOllamaLogs:    .asciz "%LOCALAPPDATA%\\Ollama\\logs"
nameAndroidStudioCache:.asciz "Android Studio cache"
pathAndroidStudioCache:.asciz "%LOCALAPPDATA%\\Google\\AndroidStudio\\cache"
nameAndroidStudioLogs:.asciz "Android Studio logs"
pathAndroidStudioLogs:.asciz "%LOCALAPPDATA%\\Google\\AndroidStudio\\log"
nameCypressCache:  .asciz "Cypress cache"
pathCypressCache:  .asciz "%LOCALAPPDATA%\\Cypress\\Cache"
nameTurboCache:    .asciz "Turborepo cache"
pathTurboCache:    .asciz "%LOCALAPPDATA%\\turbo\\cache"
nameViteCache:     .asciz "Vite cache"
pathViteCache:     .asciz "%LOCALAPPDATA%\\vite"
nameExpoCache:     .asciz "Expo cache"
pathExpoCache:     .asciz "%USERPROFILE%\\.expo"
namePrismaCache:   .asciz "Prisma cache"
pathPrismaCache:   .asciz "%LOCALAPPDATA%\\Prisma\\Cache"
nameBazelCache:    .asciz "Bazel user cache"
pathBazelCache:    .asciz "%USERPROFILE%\\_bazel_%USERNAME%"
nameRustupDownloads:.asciz "rustup downloads"
pathRustupDownloads:.asciz "%USERPROFILE%\\.rustup\\downloads"
nameRustupTmp:     .asciz "rustup tmp"
pathRustupTmp:     .asciz "%USERPROFILE%\\.rustup\\tmp"
namePipxCache:     .asciz "pipx cache"
pathPipxCache:     .asciz "%LOCALAPPDATA%\\pipx\\Cache"
nameRyeCache:      .asciz "Rye cache"
pathRyeCache:      .asciz "%USERPROFILE%\\.rye\\cache"
nameSccache:       .asciz "sccache cache"
pathSccache:       .asciz "%LOCALAPPDATA%\\Mozilla\\sccache"
nameDockerBuildx:  .asciz "Docker buildx cache"
pathDockerBuildx:  .asciz "%USERPROFILE%\\.docker\\buildx\\cache"
nameAndroidGradle: .asciz "Android Gradle cache"
pathAndroidGradle: .asciz "%USERPROFILE%\\.android\\cache"

nameSteamShader:   .asciz "Steam shadercache"
pathSteamShader:   .asciz "%PROGRAMFILES(X86)%\\Steam\\steamapps\\shadercache"
nameSteamHtmlCache:.asciz "Steam htmlcache"
pathSteamHtmlCache:.asciz "%PROGRAMFILES(X86)%\\Steam\\config\\htmlcache"
nameSteamAppCache: .asciz "Steam appcache"
pathSteamAppCache: .asciz "%PROGRAMFILES(X86)%\\Steam\\appcache"
nameSteamDepotCache:.asciz "Steam depotcache"
pathSteamDepotCache:.asciz "%PROGRAMFILES(X86)%\\Steam\\depotcache"
nameSteamDumps:    .asciz "Steam dumps"
pathSteamDumps:    .asciz "%PROGRAMFILES(X86)%\\Steam\\dumps"
nameEpicWebcache:  .asciz "Epic Games Launcher webcache"
pathEpicWebcache:  .asciz "%LOCALAPPDATA%\\EpicGamesLauncher\\Saved\\webcache"
nameBattlenet:     .asciz "Battle.net 缓存"
pathBattlenet:     .asciz "%LOCALAPPDATA%\\Battle.net\\Cache"
nameBattlenetLogs: .asciz "Battle.net logs"
pathBattlenetLogs: .asciz "%PROGRAMDATA%\\Battle.net\\Agent\\Logs"
nameEaDesktop:     .asciz "EA Desktop cache"
pathEaDesktop:     .asciz "%LOCALAPPDATA%\\Electronic Arts\\EA Desktop\\cache"
nameEaLogs:        .asciz "EA Desktop logs"
pathEaLogs:        .asciz "%LOCALAPPDATA%\\Electronic Arts\\EA Desktop\\Logs"
nameUbisoftCache:  .asciz "Ubisoft Connect cache"
pathUbisoftCache:  .asciz "%LOCALAPPDATA%\\Ubisoft Game Launcher\\cache"
nameUbisoftLogs:   .asciz "Ubisoft Connect logs"
pathUbisoftLogs:   .asciz "%LOCALAPPDATA%\\Ubisoft Game Launcher\\logs"
nameRiotLogs:      .asciz "Riot Client Logs"
pathRiotLogs:      .asciz "%LOCALAPPDATA%\\Riot Games\\Riot Client\\Logs"
nameRiotCrashes:   .asciz "Riot Client Crashes"
pathRiotCrashes:   .asciz "%LOCALAPPDATA%\\Riot Games\\Riot Client\\Crashes"
nameGogWebCache:   .asciz "GOG Galaxy webcache"
pathGogWebCache:   .asciz "%LOCALAPPDATA%\\GOG.com\\Galaxy\\Applications\\webcache"
nameGogLogs:       .asciz "GOG Galaxy logs"
pathGogLogs:       .asciz "%PROGRAMDATA%\\GOG.com\\Galaxy\\logs"
nameRobloxLogs:    .asciz "Roblox logs"
pathRobloxLogs:    .asciz "%LOCALAPPDATA%\\Roblox\\logs"
nameRobloxCache:   .asciz "Roblox cache"
pathRobloxCache:   .asciz "%LOCALAPPDATA%\\Roblox\\cache"
nameMinecraftLogs: .asciz "Minecraft logs"
pathMinecraftLogs: .asciz "%APPDATA%\\.minecraft\\logs"
nameMinecraftCrash:.asciz "Minecraft crash-reports"
pathMinecraftCrash:.asciz "%APPDATA%\\.minecraft\\crash-reports"
nameMinecraftWebCache:.asciz "Minecraft launcher webcache"
pathMinecraftWebCache:.asciz "%APPDATA%\\.minecraft\\webcache2"
nameMinecraftAssetsLog:.asciz "Minecraft launcher logs"
pathMinecraftAssetsLog:.asciz "%LOCALAPPDATA%\\Packages\\Microsoft.4297127D64EC6_8wekyb3d8bbwe\\LocalCache\\Local\\game\\launcher_log.txt"
nameModrinthCache: .asciz "Modrinth App Cache"
pathModrinthCache: .asciz "%APPDATA%\\ModrinthApp\\Cache"
nameModrinthCode:  .asciz "Modrinth App Code Cache"
pathModrinthCode:  .asciz "%APPDATA%\\ModrinthApp\\Code Cache"
nameCurseForgeCache:.asciz "CurseForge Cache"
pathCurseForgeCache:.asciz "%APPDATA%\\CurseForge\\Cache"
nameCurseForgeLogs:.asciz "CurseForge Logs"
pathCurseForgeLogs:.asciz "%APPDATA%\\CurseForge\\Logs"
namePrismLogs:     .asciz "PrismLauncher logs"
pathPrismLogs:     .asciz "%APPDATA%\\PrismLauncher\\logs"
namePrismMetaCache:.asciz "PrismLauncher metadata cache"
pathPrismMetaCache:.asciz "%APPDATA%\\PrismLauncher\\meta"
nameMultiMCLogs:   .asciz "MultiMC logs"
pathMultiMCLogs:   .asciz "%APPDATA%\\MultiMC\\logs"
nameATLauncherLogs:.asciz "ATLauncher logs"
pathATLauncherLogs:.asciz "%APPDATA%\\ATLauncher\\logs"
nameGDLauncherCache:.asciz "GDLauncher Cache"
pathGDLauncherCache:.asciz "%APPDATA%\\GDLauncher\\Cache"
nameMCreatorGradle:.asciz "MCreator Gradle 缓存"
pathMCreatorGradle:.asciz "%USERPROFILE%\\.mcreator\\gradle"
nameMCreatorCache: .asciz "MCreator 缓存"
pathMCreatorCache: .asciz "%USERPROFILE%\\.mcreator\\cache"
nameHoYoCache:     .asciz "HoYoPlay Cache"
pathHoYoCache:     .asciz "%APPDATA%\\Cognosphere\\HYP\\1_0\\Cache"
nameHoYoLogs:      .asciz "HoYoPlay logs"
pathHoYoLogs:      .asciz "%APPDATA%\\Cognosphere\\HYP\\1_0\\Logs"
nameHoYoGpu:       .asciz "HoYoPlay GPUCache"
pathHoYoGpu:       .asciz "%APPDATA%\\Cognosphere\\HYP\\1_0\\GPUCache"
nameSteamLogs:     .asciz "Steam logs"
pathSteamLogs:     .asciz "%PROGRAMFILES(X86)%\\Steam\\logs"
nameEpicLogs:      .asciz "Epic Games Launcher logs"
pathEpicLogs:      .asciz "%LOCALAPPDATA%\\EpicGamesLauncher\\Saved\\Logs"
nameEpicCrashes:   .asciz "Epic Games Launcher crashes"
pathEpicCrashes:   .asciz "%LOCALAPPDATA%\\EpicGamesLauncher\\Saved\\Crashes"
nameRockstarLogs:  .asciz "Rockstar Games Launcher logs"
pathRockstarLogs:  .asciz "%USERPROFILE%\\Documents\\Rockstar Games\\Launcher"
nameFiveMCache:    .asciz "FiveM cache"
pathFiveMCache:    .asciz "%LOCALAPPDATA%\\FiveM\\FiveM.app\\data\\cache"
nameXboxGamingCache:.asciz "Xbox Gaming App LocalCache"
pathXboxGamingCache:.asciz "%LOCALAPPDATA%\\Packages\\Microsoft.GamingApp_8wekyb3d8bbwe\\LocalCache"
nameXboxAppCache:  .asciz "Xbox App LocalCache"
pathXboxAppCache:  .asciz "%LOCALAPPDATA%\\Packages\\Microsoft.XboxApp_8wekyb3d8bbwe\\LocalCache"
nameWeGameCache:   .asciz "WeGame cache"
pathWeGameCache:   .asciz "%APPDATA%\\Tencent\\WeGame\\cache"
nameWeGameLogs:    .asciz "WeGame logs"
pathWeGameLogs:    .asciz "%APPDATA%\\Tencent\\WeGame\\logs"
nameNeteaseUULogs: .asciz "NetEase UU logs"
pathNeteaseUULogs: .asciz "%APPDATA%\\Netease\\UU\\Logs"
nameNeteaseUUCache:.asciz "NetEase UU cache"
pathNeteaseUUCache:.asciz "%LOCALAPPDATA%\\Netease\\UU\\cache"
nameNeteaseUUTemp: .asciz "NetEase UU temp"
pathNeteaseUUTemp: .asciz "%LOCALAPPDATA%\\Netease\\UU\\temp"

nameAdobeMedia:    .asciz "Adobe Media Cache Files"
pathAdobeMedia:    .asciz "%APPDATA%\\Adobe\\Common\\Media Cache Files"
nameAdobeCommon:   .asciz "Adobe Common Media Cache"
pathAdobeCommon:   .asciz "%APPDATA%\\Adobe\\Common\\Media Cache"
nameAdobePeak:     .asciz "Adobe Peak Files"
pathAdobePeak:     .asciz "%APPDATA%\\Adobe\\Common\\Peak Files"
nameUnityCache:    .asciz "Unity cache"
pathUnityCache:    .asciz "%LOCALAPPDATA%\\Unity\\cache"
nameUnityAsset:    .asciz "Unity Asset Store cache"
pathUnityAsset:    .asciz "%APPDATA%\\Unity\\Asset Store-5.x"
nameUnityShader:   .asciz "Unity shader cache"
pathUnityShader:   .asciz "%LOCALAPPDATA%\\Unity\\ShaderCache"
nameUnrealDDC:     .asciz "Unreal DerivedDataCache"
pathUnrealDDC:     .asciz "%LOCALAPPDATA%\\UnrealEngine\\Common\\DerivedDataCache"
nameUnrealLogs:    .asciz "Unreal Engine logs"
pathUnrealLogs:    .asciz "%LOCALAPPDATA%\\UnrealEngine\\Common\\Logs"
nameEpicUnrealDDC: .asciz "Epic Unreal DDC"
pathEpicUnrealDDC: .asciz "%LOCALAPPDATA%\\UnrealEngine\\DerivedDataCache"
nameBlenderTemp:   .asciz "Blender 临时缓存"
pathBlenderTemp:   .asciz "%LOCALAPPDATA%\\Temp\\blender"
nameBlenderCache:  .asciz "Blender cache"
pathBlenderCache:  .asciz "%APPDATA%\\Blender Foundation\\Blender\\Cache"
nameObsLogs:       .asciz "OBS 日志"
pathObsLogs:       .asciz "%APPDATA%\\obs-studio\\logs"
nameObsCrashDumps: .asciz "OBS crash dumps"
pathObsCrashDumps: .asciz "%APPDATA%\\obs-studio\\crashes"
nameAudacityTemp:  .asciz "Audacity temp"
pathAudacityTemp:  .asciz "%LOCALAPPDATA%\\Audacity\\SessionData"
nameShotcutCache:  .asciz "Shotcut cache"
pathShotcutCache:  .asciz "%LOCALAPPDATA%\\Meltytech\\Shotcut\\cache"
nameKdenliveCache: .asciz "Kdenlive cache"
pathKdenliveCache: .asciz "%LOCALAPPDATA%\\kdenlive\\cache"
nameGimpTemp:      .asciz "GIMP temp"
pathGimpTemp:      .asciz "%LOCALAPPDATA%\\Temp\\gimp"
nameInkscapeCache: .asciz "Inkscape cache"
pathInkscapeCache: .asciz "%LOCALAPPDATA%\\inkscape\\cache"
nameKritaCache:    .asciz "Krita cache"
pathKritaCache:    .asciz "%LOCALAPPDATA%\\krita\\cache"
namePaintDotNetTemp:.asciz "paint.net temp"
pathPaintDotNetTemp:.asciz "%LOCALAPPDATA%\\paint.net\\Temp"
nameShareXLogs:    .asciz "ShareX logs"
pathShareXLogs:    .asciz "%USERPROFILE%\\Documents\\ShareX\\Logs"
nameScreenToGifTemp:.asciz "ScreenToGif temp"
pathScreenToGifTemp:.asciz "%LOCALAPPDATA%\\ScreenToGif\\Temp"
nameXnViewCache:   .asciz "XnView cache"
pathXnViewCache:   .asciz "%APPDATA%\\XnViewMP\\cache"
nameFoobarCache:   .asciz "foobar2000 cache"
pathFoobarCache:   .asciz "%APPDATA%\\foobar2000\\cache"
nameFoobarLogs:    .asciz "foobar2000 logs"
pathFoobarLogs:    .asciz "%APPDATA%\\foobar2000\\logs"
nameMpvCache:      .asciz "mpv cache"
pathMpvCache:      .asciz "%APPDATA%\\mpv\\cache"
nameClipchampCache:.asciz "Clipchamp cache"
pathClipchampCache:.asciz "%LOCALAPPDATA%\\Packages\\Clipchamp.Clipchamp_yxz26nhyzhsrt\\LocalCache"
nameFilmoraCache:  .asciz "Wondershare Filmora cache"
pathFilmoraCache:  .asciz "%LOCALAPPDATA%\\Wondershare\\Wondershare Filmora\\Cache"
nameFilmoraLogs:   .asciz "Wondershare Filmora logs"
pathFilmoraLogs:   .asciz "%APPDATA%\\Wondershare\\Wondershare Filmora\\Log"
nameMovaviCache:   .asciz "Movavi cache"
pathMovaviCache:   .asciz "%LOCALAPPDATA%\\Movavi\\Cache"
nameCamtasiaCache: .asciz "Camtasia cache"
pathCamtasiaCache: .asciz "%LOCALAPPDATA%\\TechSmith\\Camtasia Studio\\Cache"
nameSnagitCache:   .asciz "Snagit cache"
pathSnagitCache:   .asciz "%LOCALAPPDATA%\\TechSmith\\Snagit\\Cache"
namePowerToysLogs: .asciz "PowerToys 日志"
pathPowerToysLogs: .asciz "%LOCALAPPDATA%\\Microsoft\\PowerToys\\Logs"
nameOneDriveLogs:  .asciz "OneDrive 日志"
pathOneDriveLogs:  .asciz "%LOCALAPPDATA%\\Microsoft\\OneDrive\\logs"
nameOfficeCache:   .asciz "Office 文档缓存"
pathOfficeCache:   .asciz "%LOCALAPPDATA%\\Microsoft\\Office\\16.0\\OfficeFileCache"
nameOutlookTemp:   .asciz "Outlook 临时附件"
pathOutlookTemp:   .asciz "%LOCALAPPDATA%\\Microsoft\\Windows\\INetCache\\Content.Outlook"
nameQQMusicCache:  .asciz "QQ 音乐缓存"
pathQQMusicCache:  .asciz "%APPDATA%\\Tencent\\QQMusic"
nameQQMusicLocal:  .asciz "QQ 音乐本地缓存"
pathQQMusicLocal:  .asciz "%LOCALAPPDATA%\\Tencent\\QQMusic\\Cache"
nameTencentVideo:  .asciz "腾讯视频缓存"
pathTencentVideo:  .asciz "%APPDATA%\\Tencent\\QQLive"
nameTencentVideoCache:.asciz "腾讯视频本地缓存"
pathTencentVideoCache:.asciz "%LOCALAPPDATA%\\Tencent\\QQLive\\Cache"
nameIqiyiCache:    .asciz "爱奇艺缓存"
pathIqiyiCache:    .asciz "%APPDATA%\\IQIYI Video"
nameIqiyiLocal:    .asciz "爱奇艺本地缓存"
pathIqiyiLocal:    .asciz "%LOCALAPPDATA%\\IQIYI Video\\Cache"
nameBilibiliCache: .asciz "哔哩哔哩缓存"
pathBilibiliCache: .asciz "%LOCALAPPDATA%\\bilibili"
nameBilibiliLogs:  .asciz "哔哩哔哩日志"
pathBilibiliLogs:  .asciz "%LOCALAPPDATA%\\bilibili\\logs"
namePotPlayerCache:.asciz "PotPlayer 缓存"
pathPotPlayerCache:.asciz "%APPDATA%\\PotPlayerMini64"
nameCapCutCache:   .asciz "CapCut Cache"
pathCapCutCache:   .asciz "%LOCALAPPDATA%\\CapCut\\User Data\\Default\\Cache"
nameCapCutCode:    .asciz "CapCut Code Cache"
pathCapCutCode:    .asciz "%LOCALAPPDATA%\\CapCut\\User Data\\Default\\Code Cache"
nameCapCutGpu:     .asciz "CapCut GPUCache"
pathCapCutGpu:     .asciz "%LOCALAPPDATA%\\CapCut\\User Data\\Default\\GPUCache"
nameAdobeAeCache:  .asciz "After Effects Disk Cache"
pathAdobeAeCache:  .asciz "%APPDATA%\\Adobe\\After Effects\\Disk Cache"
nameDaVinciCache:  .asciz "DaVinci Resolve CacheClip"
pathDaVinciCache:  .asciz "%APPDATA%\\Blackmagic Design\\DaVinci Resolve\\Support\\Resolve Disk Database\\Resolve Projects\\CacheClip"
nameDaVinciLogs:   .asciz "DaVinci Resolve logs"
pathDaVinciLogs:   .asciz "%APPDATA%\\Blackmagic Design\\DaVinci Resolve\\Support\\logs"
nameHandBrakeLogs: .asciz "HandBrake logs"
pathHandBrakeLogs: .asciz "%APPDATA%\\HandBrake\\logs"
nameAimpCache:     .asciz "AIMP cache"
pathAimpCache:     .asciz "%APPDATA%\\AIMP\\Cache"
nameNeteaseMusicWebCache:.asciz "Netease Music Web Cache"
pathNeteaseMusicWebCache:.asciz "%LOCALAPPDATA%\\Netease\\CloudMusic\\webdata\\Cache"
nameNeteaseMusicGpu:.asciz "Netease Music GPUCache"
pathNeteaseMusicGpu:.asciz "%LOCALAPPDATA%\\Netease\\CloudMusic\\GPUCache"
nameQQMusicLogs:   .asciz "QQ Music logs"
pathQQMusicLogs:   .asciz "%APPDATA%\\Tencent\\QQMusic\\Logs"
nameQQMusicGpu:    .asciz "QQ Music GPUCache"
pathQQMusicGpu:    .asciz "%APPDATA%\\Tencent\\QQMusic\\GPUCache"
nameKugouLogs:     .asciz "KuGou logs"
pathKugouLogs:     .asciz "%APPDATA%\\KuGou8\\Log"
nameKugouTemp:     .asciz "KuGou temp"
pathKugouTemp:     .asciz "%LOCALAPPDATA%\\KuGou\\Temp"
nameKuwoLogs:      .asciz "Kuwo logs"
pathKuwoLogs:      .asciz "%APPDATA%\\KuwoMusic\\log"
nameTencentVideoLogs:.asciz "Tencent Video logs"
pathTencentVideoLogs:.asciz "%APPDATA%\\Tencent\\QQLive\\Log"
nameTencentVideoGpu:.asciz "Tencent Video GPUCache"
pathTencentVideoGpu:.asciz "%APPDATA%\\Tencent\\QQLive\\GPUCache"
nameIqiyiLogs:     .asciz "iQIYI logs"
pathIqiyiLogs:     .asciz "%APPDATA%\\IQIYI Video\\Logs"
nameIqiyiGpu:      .asciz "iQIYI GPUCache"
pathIqiyiGpu:      .asciz "%APPDATA%\\IQIYI Video\\GPUCache"
nameYoukuCache:    .asciz "Youku Cache"
pathYoukuCache:    .asciz "%APPDATA%\\Youku\\Cache"
nameYoukuLogs:     .asciz "Youku logs"
pathYoukuLogs:     .asciz "%APPDATA%\\Youku\\Logs"
nameYoukuGpu:      .asciz "Youku GPUCache"
pathYoukuGpu:      .asciz "%APPDATA%\\Youku\\GPUCache"
nameMangoTVCache:  .asciz "MangoTV Cache"
pathMangoTVCache:  .asciz "%APPDATA%\\MGTV\\Cache"
nameMangoTVLogs:   .asciz "MangoTV logs"
pathMangoTVLogs:   .asciz "%APPDATA%\\MGTV\\Logs"
nameMangoTVGpu:    .asciz "MangoTV GPUCache"
pathMangoTVGpu:    .asciz "%APPDATA%\\MGTV\\GPUCache"
nameBilibiliGpu:   .asciz "Bilibili GPUCache"
pathBilibiliGpu:   .asciz "%LOCALAPPDATA%\\bilibili\\GPUCache"
nameBilibiliCrash: .asciz "Bilibili Crashpad"
pathBilibiliCrash: .asciz "%LOCALAPPDATA%\\bilibili\\Crashpad"
nameDouyinCache:   .asciz "Douyin Cache"
pathDouyinCache:   .asciz "%APPDATA%\\douyin\\Cache"
nameDouyinLogs:    .asciz "Douyin logs"
pathDouyinLogs:    .asciz "%APPDATA%\\douyin\\logs"
nameDouyinGpu:     .asciz "Douyin GPUCache"
pathDouyinGpu:     .asciz "%APPDATA%\\douyin\\GPUCache"
nameDouyinCrash:   .asciz "Douyin Crashpad"
pathDouyinCrash:   .asciz "%APPDATA%\\douyin\\Crashpad"
nameJianyingCache: .asciz "Jianying Cache"
pathJianyingCache: .asciz "%LOCALAPPDATA%\\JianyingPro\\User Data\\Default\\Cache"
nameJianyingCode:  .asciz "Jianying Code Cache"
pathJianyingCode:  .asciz "%LOCALAPPDATA%\\JianyingPro\\User Data\\Default\\Code Cache"
nameJianyingGpu:   .asciz "Jianying GPUCache"
pathJianyingGpu:   .asciz "%LOCALAPPDATA%\\JianyingPro\\User Data\\Default\\GPUCache"
nameJianyingLogs:  .asciz "Jianying logs"
pathJianyingLogs:  .asciz "%APPDATA%\\JianyingPro\\logs"
nameHuyaCache:     .asciz "Huya Live cache"
pathHuyaCache:     .asciz "%APPDATA%\\Huya\\Cache"
nameHuyaLogs:      .asciz "Huya Live logs"
pathHuyaLogs:      .asciz "%APPDATA%\\Huya\\logs"
nameDouyuCache:    .asciz "Douyu Live cache"
pathDouyuCache:    .asciz "%APPDATA%\\Douyu\\Cache"
nameDouyuLogs:     .asciz "Douyu Live logs"
pathDouyuLogs:     .asciz "%APPDATA%\\Douyu\\logs"
nameKuaishouCache: .asciz "Kuaishou cache"
pathKuaishouCache: .asciz "%APPDATA%\\Kuaishou\\Cache"
nameKuaishouLogs:  .asciz "Kuaishou logs"
pathKuaishouLogs:  .asciz "%APPDATA%\\Kuaishou\\logs"
nameKuaishouGpu:   .asciz "Kuaishou GPUCache"
pathKuaishouGpu:   .asciz "%APPDATA%\\Kuaishou\\GPUCache"
nameKuaishouCrash: .asciz "Kuaishou Crashpad"
pathKuaishouCrash: .asciz "%APPDATA%\\Kuaishou\\Crashpad"
nameXimalayaCache: .asciz "Ximalaya cache"
pathXimalayaCache: .asciz "%APPDATA%\\Ximalaya\\Cache"
nameXimalayaLogs:  .asciz "Ximalaya logs"
pathXimalayaLogs:  .asciz "%APPDATA%\\Ximalaya\\logs"
nameLizhiCache:    .asciz "Lizhi cache"
pathLizhiCache:    .asciz "%APPDATA%\\Lizhi\\Cache"
nameLizhiLogs:     .asciz "Lizhi logs"
pathLizhiLogs:     .asciz "%APPDATA%\\Lizhi\\logs"
nameBaiduMusicCache:.asciz "Baidu Music cache"
pathBaiduMusicCache:.asciz "%APPDATA%\\Baidu\\BaiduMusic\\Cache"
nameBaiduMusicLogs:.asciz "Baidu Music logs"
pathBaiduMusicLogs:.asciz "%APPDATA%\\Baidu\\BaiduMusic\\logs"
nameSohuVideoCache:.asciz "Sohu Video Cache"
pathSohuVideoCache:.asciz "%APPDATA%\\SohuVideo\\Cache"
nameSohuVideoLogs: .asciz "Sohu Video logs"
pathSohuVideoLogs: .asciz "%APPDATA%\\SohuVideo\\logs"
namePptvCache:     .asciz "PPTV Cache"
pathPptvCache:     .asciz "%APPDATA%\\PPLive\\Cache"
namePptvLogs:      .asciz "PPTV logs"
pathPptvLogs:      .asciz "%APPDATA%\\PPLive\\logs"
nameAcFunCache:    .asciz "AcFun Cache"
pathAcFunCache:    .asciz "%APPDATA%\\AcFun\\Cache"
nameAcFunLogs:     .asciz "AcFun logs"
pathAcFunLogs:     .asciz "%APPDATA%\\AcFun\\logs"
nameVlcArtCache:   .asciz "VLC art cache"
pathVlcArtCache:   .asciz "%APPDATA%\\vlc\\art"
nameKugouCache:    .asciz "KuGou cache"
pathKugouCache:    .asciz "%APPDATA%\\KuGou8"
nameKuwoCache:     .asciz "Kuwo Music cache"
pathKuwoCache:     .asciz "%APPDATA%\\KuwoMusic"
nameNvidiaDownloader:.asciz "NVIDIA driver downloader cache"
pathNvidiaDownloader:.asciz "%PROGRAMDATA%\\NVIDIA Corporation\\Downloader"
nameNvidiaGfeCef:  .asciz "NVIDIA GeForce Experience CefCache"
pathNvidiaGfeCef:  .asciz "%LOCALAPPDATA%\\NVIDIA Corporation\\NVIDIA GeForce Experience\\CefCache"
nameQQGameCache:   .asciz "QQGame cache"
pathQQGameCache:   .asciz "%APPDATA%\\Tencent\\QQGame\\Cache"
nameQQGameLogs:    .asciz "QQGame logs"
pathQQGameLogs:    .asciz "%APPDATA%\\Tencent\\QQGame\\logs"
nameWeGameDownloadCache:.asciz "WeGame download cache"
pathWeGameDownloadCache:.asciz "%APPDATA%\\Tencent\\WeGame\\Download\\Cache"
nameWeGameWebCache:.asciz "WeGame web cache"
pathWeGameWebCache:.asciz "%APPDATA%\\Tencent\\WeGame\\webcache"
nameYuanShenCache: .asciz "Genshin Impact web cache"
pathYuanShenCache: .asciz "%USERPROFILE%\\AppData\\LocalLow\\miHoYo\\Genshin Impact\\webCaches"
nameStarRailCache: .asciz "Star Rail web cache"
pathStarRailCache: .asciz "%USERPROFILE%\\AppData\\LocalLow\\Cognosphere\\Star Rail\\webCaches"
nameNeteaseGameCache:.asciz "NetEase Game cache"
pathNeteaseGameCache:.asciz "%APPDATA%\\NetEase\\Game\\Cache"
nameNeteaseGameLogs:.asciz "NetEase Game logs"
pathNeteaseGameLogs:.asciz "%APPDATA%\\NetEase\\Game\\logs"
nameMuMuLogs:      .asciz "MuMu Player logs"
pathMuMuLogs:      .asciz "%APPDATA%\\Netease\\MuMuPlayer\\logs"
nameMuMuCache:     .asciz "MuMu Player cache"
pathMuMuCache:     .asciz "%APPDATA%\\Netease\\MuMuPlayer\\cache"
nameLDPlayerLogs:  .asciz "LDPlayer logs"
pathLDPlayerLogs:  .asciz "%APPDATA%\\XuanZhi\\LDPlayer\\log"
nameLDPlayerCache: .asciz "LDPlayer cache"
pathLDPlayerCache: .asciz "%APPDATA%\\XuanZhi\\LDPlayer\\cache"
nameLanternCache:  .asciz "Lantern cache"
pathLanternCache:  .asciz "%APPDATA%\\Lantern\\Cache"
nameLanternLogs:   .asciz "Lantern logs"
pathLanternLogs:   .asciz "%APPDATA%\\Lantern\\logs"
namePlayniteCache: .asciz "Playnite cache"
pathPlayniteCache: .asciz "%APPDATA%\\Playnite\\cache"
namePlayniteLogs:  .asciz "Playnite logs"
pathPlayniteLogs:  .asciz "%APPDATA%\\Playnite\\logs"
nameHeroicCache:   .asciz "Heroic Games Launcher Cache"
pathHeroicCache:   .asciz "%APPDATA%\\heroic\\Cache"
nameHeroicLogs:    .asciz "Heroic Games Launcher logs"
pathHeroicLogs:    .asciz "%APPDATA%\\heroic\\logs"
nameOverwolfCache: .asciz "Overwolf cache"
pathOverwolfCache: .asciz "%LOCALAPPDATA%\\Overwolf\\BrowserCache"
nameOverwolfLogs:  .asciz "Overwolf logs"
pathOverwolfLogs:  .asciz "%LOCALAPPDATA%\\Overwolf\\Log"
nameItchCache:     .asciz "itch cache"
pathItchCache:     .asciz "%APPDATA%\\itch\\Cache"
nameItchLogs:      .asciz "itch logs"
pathItchLogs:      .asciz "%APPDATA%\\itch\\logs"
nameParadoxCache:  .asciz "Paradox Launcher cache"
pathParadoxCache:  .asciz "%LOCALAPPDATA%\\Paradox Interactive\\launcher-cache"
nameParadoxLogs:   .asciz "Paradox Launcher logs"
pathParadoxLogs:   .asciz "%LOCALAPPDATA%\\Paradox Interactive\\launcher-v2\\logs"
nameBlueStacksLogs:.asciz "BlueStacks logs"
pathBlueStacksLogs:.asciz "%PROGRAMDATA%\\BlueStacks_nxt\\Logs"
nameBlueStacksCache:.asciz "BlueStacks cache"
pathBlueStacksCache:.asciz "%PROGRAMDATA%\\BlueStacks_nxt\\Engine\\UserData\\SharedFolder"
nameNoxLogs:       .asciz "Nox logs"
pathNoxLogs:       .asciz "%LOCALAPPDATA%\\Nox\\logs"
nameNoxCache:      .asciz "Nox cache"
pathNoxCache:      .asciz "%LOCALAPPDATA%\\Nox\\cache"

.align 8
targetTable:
    .quad nameUserTemp,     pathUserTemp,     riskLow,    1, CAT_WINDOWS
    .quad nameLocalTemp,    pathLocalTemp,    riskLow,    1, CAT_WINDOWS
    .quad nameInetCache,    pathInetCache,    riskMedium, 0, CAT_WINDOWS
    .quad nameThumbs,       pathThumbs,       riskMedium, 0, CAT_WINDOWS
    .quad nameCrashDumps,   pathCrashDumps,   riskLow,    1, CAT_WINDOWS
    .quad nameWer,          pathWer,          riskLow,    1, CAT_WINDOWS
    .quad nameD3D,          pathD3D,          riskLow,    1, CAT_WINDOWS
    .quad nameDelivery,     pathDelivery,     riskHigh,   1, CAT_WINDOWS
    .quad nameWinTemp,      pathWinTemp,      riskHigh,   1, CAT_WINDOWS
    .quad nameRecycleBin,   pathRecycleBin,   riskHigh,   1, CAT_RECYCLE
    .quad nameWinUpdate,    pathWinUpdate,    riskHigh,   1, CAT_WINDOWS
    .quad nameNvidiaDx,     pathNvidiaDx,     riskLow,    1, CAT_WINDOWS
    .quad nameNvidiaGl,     pathNvidiaGl,     riskLow,    1, CAT_WINDOWS
    .quad nameNvidiaCompute,pathNvidiaCompute,riskLow,    1, CAT_WINDOWS
    .quad nameAmdDx,        pathAmdDx,        riskLow,    1, CAT_WINDOWS
    .quad nameAmdGl,        pathAmdGl,        riskLow,    1, CAT_WINDOWS
    .quad nameVulkanCache,  pathVulkanCache,  riskLow,    1, CAT_WINDOWS
    .quad nameIntelShader,  pathIntelShader,  riskLow,    1, CAT_WINDOWS
    .quad nameWinCaches,    pathWinCaches,    riskLow,    1, CAT_WINDOWS
    .quad nameWinWebCache,  pathWinWebCache,  riskLow,    1, CAT_WINDOWS
    .quad nameWinFontCache, pathWinFontCache, riskMedium, 1, CAT_WINDOWS
    .quad nameWinPrefetch,  pathWinPrefetch,  riskMedium, 1, CAT_WINDOWS
    .quad nameWinCbsLogs,   pathWinCbsLogs,   riskLow,    1, CAT_WINDOWS
    .quad nameWinDismLogs,  pathWinDismLogs,  riskLow,    1, CAT_WINDOWS
    .quad nameDirectXShader,pathDirectXShader,riskLow,    1, CAT_WINDOWS
    .quad nameProgramDataWer,pathProgramDataWer,riskLow,  1, CAT_WINDOWS
    .quad nameWindowsPanther,pathWindowsPanther,riskLow,  1, CAT_WINDOWS
    .quad nameChromeCache,  pathChromeCache,  riskLow,    1, CAT_BROWSER
    .quad nameChromeCode,   pathChromeCode,   riskLow,    1, CAT_BROWSER
    .quad nameChromeGpu,    pathChromeGpu,    riskLow,    1, CAT_BROWSER
    .quad nameChromeP1Cache,pathChromeP1Cache,riskLow,    1, CAT_BROWSER
    .quad nameChromeP1Code, pathChromeP1Code, riskLow,    1, CAT_BROWSER
    .quad nameChromeP2Cache,pathChromeP2Cache,riskLow,    1, CAT_BROWSER
    .quad nameChromeP2Code, pathChromeP2Code, riskLow,    1, CAT_BROWSER
    .quad nameChromeP3Cache,pathChromeP3Cache,riskLow,    1, CAT_BROWSER
    .quad nameChromeP3Code, pathChromeP3Code, riskLow,    1, CAT_BROWSER
    .quad nameChromeP3Gpu,  pathChromeP3Gpu,  riskLow,    1, CAT_BROWSER
    .quad nameChromeP4Cache,pathChromeP4Cache,riskLow,    1, CAT_BROWSER
    .quad nameChromeP4Code, pathChromeP4Code, riskLow,    1, CAT_BROWSER
    .quad nameChromeP4Gpu,  pathChromeP4Gpu,  riskLow,    1, CAT_BROWSER
    .quad nameChromeP5Cache,pathChromeP5Cache,riskLow,    1, CAT_BROWSER
    .quad nameChromeP5Code, pathChromeP5Code, riskLow,    1, CAT_BROWSER
    .quad nameChromeP5Gpu,  pathChromeP5Gpu,  riskLow,    1, CAT_BROWSER
    .quad nameChromeCrashpad,pathChromeCrashpad,riskLow,   1, CAT_BROWSER
    .quad nameEdgeCache,    pathEdgeCache,    riskLow,    1, CAT_BROWSER
    .quad nameEdgeCode,     pathEdgeCode,     riskLow,    1, CAT_BROWSER
    .quad nameEdgeGpu,      pathEdgeGpu,      riskLow,    1, CAT_BROWSER
    .quad nameEdgeP1Cache,  pathEdgeP1Cache,  riskLow,    1, CAT_BROWSER
    .quad nameEdgeP1Code,   pathEdgeP1Code,   riskLow,    1, CAT_BROWSER
    .quad nameEdgeP2Cache,  pathEdgeP2Cache,  riskLow,    1, CAT_BROWSER
    .quad nameEdgeP2Code,   pathEdgeP2Code,   riskLow,    1, CAT_BROWSER
    .quad nameEdgeP3Cache,  pathEdgeP3Cache,  riskLow,    1, CAT_BROWSER
    .quad nameEdgeP3Code,   pathEdgeP3Code,   riskLow,    1, CAT_BROWSER
    .quad nameEdgeP3Gpu,    pathEdgeP3Gpu,    riskLow,    1, CAT_BROWSER
    .quad nameEdgeP4Cache,  pathEdgeP4Cache,  riskLow,    1, CAT_BROWSER
    .quad nameEdgeP4Code,   pathEdgeP4Code,   riskLow,    1, CAT_BROWSER
    .quad nameEdgeP4Gpu,    pathEdgeP4Gpu,    riskLow,    1, CAT_BROWSER
    .quad nameEdgeP5Cache,  pathEdgeP5Cache,  riskLow,    1, CAT_BROWSER
    .quad nameEdgeP5Code,   pathEdgeP5Code,   riskLow,    1, CAT_BROWSER
    .quad nameEdgeP5Gpu,    pathEdgeP5Gpu,    riskLow,    1, CAT_BROWSER
    .quad nameEdgeCrashpad, pathEdgeCrashpad, riskLow,    1, CAT_BROWSER
    .quad nameFirefoxRoam,  pathFirefoxRoam,  riskMedium, 0, CAT_BROWSER
    .quad nameFirefoxLocal, pathFirefoxLocal, riskLow,    1, CAT_BROWSER
    .quad nameBraveCache,   pathBraveCache,   riskLow,    1, CAT_BROWSER
    .quad nameBraveCode,    pathBraveCode,    riskLow,    1, CAT_BROWSER
    .quad nameBraveGpu,     pathBraveGpu,     riskLow,    1, CAT_BROWSER
    .quad nameBraveP1Cache, pathBraveP1Cache, riskLow,    1, CAT_BROWSER
    .quad nameBraveP1Code,  pathBraveP1Code,  riskLow,    1, CAT_BROWSER
    .quad nameBraveP2Cache, pathBraveP2Cache, riskLow,    1, CAT_BROWSER
    .quad nameBraveP2Code,  pathBraveP2Code,  riskLow,    1, CAT_BROWSER
    .quad nameBraveCrashpad,pathBraveCrashpad,riskLow,    1, CAT_BROWSER
    .quad nameOperaCache,   pathOperaCache,   riskLow,    1, CAT_BROWSER
    .quad nameOperaCode,    pathOperaCode,    riskLow,    1, CAT_BROWSER
    .quad nameOperaGpu,     pathOperaGpu,     riskLow,    1, CAT_BROWSER
    .quad nameOperaCrash,   pathOperaCrash,   riskLow,    1, CAT_BROWSER
    .quad nameOperaGxCache, pathOperaGxCache, riskLow,    1, CAT_BROWSER
    .quad nameOperaGxCode,  pathOperaGxCode,  riskLow,    1, CAT_BROWSER
    .quad nameOperaGxGpu,   pathOperaGxGpu,   riskLow,    1, CAT_BROWSER
    .quad nameQQBrowser,    pathQQBrowser,    riskLow,    1, CAT_BROWSER
    .quad nameQQBrowserCode,pathQQBrowserCode,riskLow,    1, CAT_BROWSER
    .quad nameQQBrowserGpu, pathQQBrowserGpu, riskLow,    1, CAT_BROWSER
    .quad nameQQBrowserCrashpad,pathQQBrowserCrashpad,riskLow,1, CAT_BROWSER
    .quad nameSogouBrowser, pathSogouBrowser, riskLow,    1, CAT_BROWSER
    .quad nameSogouBrowserCode,pathSogouBrowserCode,riskLow,1, CAT_BROWSER
    .quad nameSogouGpu,     pathSogouGpu,     riskLow,    1, CAT_BROWSER
    .quad nameChrome360,    pathChrome360,    riskLow,    1, CAT_BROWSER
    .quad nameChrome360Code,pathChrome360Code,riskLow,    1, CAT_BROWSER
    .quad nameChrome360Gpu, pathChrome360Gpu, riskLow,    1, CAT_BROWSER
    .quad nameChrome360XCache,pathChrome360XCache,riskLow,1, CAT_BROWSER
    .quad nameChrome360XCode,pathChrome360XCode,riskLow,1, CAT_BROWSER
    .quad nameChrome360XGpu,pathChrome360XGpu,riskLow,1, CAT_BROWSER
    .quad nameBrowser360SafeCache,pathBrowser360SafeCache,riskLow,1, CAT_BROWSER
    .quad nameBrowser360SafeCode,pathBrowser360SafeCode,riskLow,1, CAT_BROWSER
    .quad nameBrowser360SafeGpu,pathBrowser360SafeGpu,riskLow,1, CAT_BROWSER
    .quad nameMaxthonCache, pathMaxthonCache, riskLow,    1, CAT_BROWSER
    .quad nameMaxthonCode,  pathMaxthonCode,  riskLow,    1, CAT_BROWSER
    .quad nameBrowser2345Cache,pathBrowser2345Cache,riskLow,1, CAT_BROWSER
    .quad nameBrowser2345Code,pathBrowser2345Code,riskLow,1, CAT_BROWSER
    .quad nameBrowser2345Gpu,pathBrowser2345Gpu,riskLow,1, CAT_BROWSER
    .quad nameLiebaoCache,  pathLiebaoCache,  riskLow,    1, CAT_BROWSER
    .quad nameLiebaoCode,   pathLiebaoCode,   riskLow,    1, CAT_BROWSER
    .quad nameUCWebCache,   pathUCWebCache,   riskLow,    1, CAT_BROWSER
    .quad nameUCWebCode,    pathUCWebCode,    riskLow,    1, CAT_BROWSER
    .quad nameQuarkBrowserCache,pathQuarkBrowserCache,riskLow,1, CAT_BROWSER
    .quad nameQuarkBrowserCode,pathQuarkBrowserCode,riskLow,1, CAT_BROWSER
    .quad nameQuarkBrowserGpu,pathQuarkBrowserGpu,riskLow,1, CAT_BROWSER
    .quad nameBaiduBrowserCache,pathBaiduBrowserCache,riskLow,1, CAT_BROWSER
    .quad nameBaiduBrowserCode,pathBaiduBrowserCode,riskLow,1, CAT_BROWSER
    .quad nameBaiduBrowserGpu,pathBaiduBrowserGpu,riskLow,1, CAT_BROWSER
    .quad nameWhaleCache,   pathWhaleCache,   riskLow,    1, CAT_BROWSER
    .quad nameWhaleCode,    pathWhaleCode,    riskLow,    1, CAT_BROWSER
    .quad nameWhaleGpu,     pathWhaleGpu,     riskLow,    1, CAT_BROWSER
    .quad nameVivaldiCache, pathVivaldiCache, riskLow,    1, CAT_BROWSER
    .quad nameVivaldiCode,  pathVivaldiCode,  riskLow,    1, CAT_BROWSER
    .quad nameVivaldiGpu,   pathVivaldiGpu,   riskLow,    1, CAT_BROWSER
    .quad nameVivaldiP1Cache,pathVivaldiP1Cache,riskLow, 1, CAT_BROWSER
    .quad nameVivaldiP1Code,pathVivaldiP1Code,riskLow,   1, CAT_BROWSER
    .quad nameVivaldiP2Cache,pathVivaldiP2Cache,riskLow, 1, CAT_BROWSER
    .quad nameVivaldiP2Code,pathVivaldiP2Code,riskLow,   1, CAT_BROWSER
    .quad nameYandexCache,  pathYandexCache,  riskLow,    1, CAT_BROWSER
    .quad nameYandexCode,   pathYandexCode,   riskLow,    1, CAT_BROWSER
    .quad nameYandexGpu,    pathYandexGpu,    riskLow,    1, CAT_BROWSER
    .quad nameCentCache,    pathCentCache,    riskLow,    1, CAT_BROWSER
    .quad nameArcCache,     pathArcCache,     riskLow,    1, CAT_BROWSER
    .quad nameCocCocCache,  pathCocCocCache,  riskLow,    1, CAT_BROWSER
    .quad nameWaterfoxLocal,pathWaterfoxLocal,riskLow,    1, CAT_BROWSER
    .quad nameLibreWolfLocal,pathLibreWolfLocal,riskLow,  1, CAT_BROWSER
    .quad nameVscodeCache,  pathVscodeCache,  riskLow,    1, CAT_APP
    .quad nameVscodeData,   pathVscodeData,   riskLow,    1, CAT_APP
    .quad nameVscodeGpu,    pathVscodeGpu,    riskLow,    1, CAT_APP
    .quad nameVscodeLogs,   pathVscodeLogs,   riskLow,    1, CAT_APP
    .quad nameVscodeCrashpad,pathVscodeCrashpad,riskLow,  1, CAT_APP
    .quad nameDiscordCache, pathDiscordCache, riskLow,    1, CAT_APP
    .quad nameDiscordCode,  pathDiscordCode,  riskLow,    1, CAT_APP
    .quad nameDiscordGpu,   pathDiscordGpu,   riskLow,    1, CAT_APP
    .quad nameDiscordLogs,  pathDiscordLogs,  riskLow,    1, CAT_APP
    .quad nameDiscordCrash, pathDiscordCrash, riskLow,    1, CAT_APP
    .quad nameTeamsCache,   pathTeamsCache,   riskMedium, 0, CAT_APP
    .quad nameTeamsNewTemp, pathTeamsNewTemp, riskLow,    1, CAT_APP
    .quad nameTeamsClassicCache,pathTeamsClassicCache,riskLow,1, CAT_APP
    .quad nameTeamsClassicCode,pathTeamsClassicCode,riskLow,1, CAT_APP
    .quad nameTeamsClassicGpu,pathTeamsClassicGpu,riskLow,1, CAT_APP
    .quad nameTelegram,     pathTelegram,     riskMedium, 0, CAT_APP
    .quad nameDingTalkCache,pathDingTalkCache,riskLow,    1, CAT_APP
    .quad nameFeishuCache,  pathFeishuCache,  riskLow,    1, CAT_APP
    .quad nameLarkCache,    pathLarkCache,    riskLow,    1, CAT_APP
    .quad nameWpsCache,     pathWpsCache,     riskLow,    1, CAT_APP
    .quad nameZoomCache,    pathZoomCache,    riskLow,    1, CAT_APP
    .quad nameZoomLogs,     pathZoomLogs,     riskLow,    1, CAT_APP
    .quad nameSkypeCache,   pathSkypeCache,   riskLow,    1, CAT_APP
    .quad nameSkypeCode,    pathSkypeCode,    riskLow,    1, CAT_APP
    .quad nameSkypeGpu,     pathSkypeGpu,     riskLow,    1, CAT_APP
    .quad nameLineCache,    pathLineCache,    riskLow,    1, CAT_APP
    .quad nameViberCache,   pathViberCache,   riskLow,    1, CAT_APP
    .quad nameViberLogs,    pathViberLogs,    riskLow,    1, CAT_APP
    .quad nameElementCache, pathElementCache, riskLow,    1, CAT_APP
    .quad nameElementCode,  pathElementCode,  riskLow,    1, CAT_APP
    .quad nameElementGpu,   pathElementGpu,   riskLow,    1, CAT_APP
    .quad nameMattermostCache,pathMattermostCache,riskLow,1, CAT_APP
    .quad nameMattermostCode,pathMattermostCode,riskLow,  1, CAT_APP
    .quad nameMattermostGpu,pathMattermostGpu,riskLow,    1, CAT_APP
    .quad nameSpotifyCache, pathSpotifyCache, riskLow,    1, CAT_MEDIA
    .quad nameSlackCache,   pathSlackCache,   riskLow,    1, CAT_APP
    .quad nameSlackCode,    pathSlackCode,    riskLow,    1, CAT_APP
    .quad nameSlackGpu,     pathSlackGpu,     riskLow,    1, CAT_APP
    .quad nameSlackLogs,    pathSlackLogs,    riskLow,    1, CAT_APP
    .quad namePostmanCache, pathPostmanCache, riskLow,    1, CAT_DEV
    .quad namePostmanCode,  pathPostmanCode,  riskLow,    1, CAT_DEV
    .quad namePostmanGpu,   pathPostmanGpu,   riskLow,    1, CAT_DEV
    .quad namePostmanLogs,  pathPostmanLogs,  riskLow,    1, CAT_DEV
    .quad nameNotionCache,  pathNotionCache,  riskLow,    1, CAT_APP
    .quad nameNotionCode,   pathNotionCode,   riskLow,    1, CAT_APP
    .quad nameNotionGpu,    pathNotionGpu,    riskLow,    1, CAT_APP
    .quad nameNotionLogs,   pathNotionLogs,   riskLow,    1, CAT_APP
    .quad nameFigmaCache,   pathFigmaCache,   riskLow,    1, CAT_APP
    .quad nameFigmaCode,    pathFigmaCode,    riskLow,    1, CAT_APP
    .quad nameFigmaGpu,     pathFigmaGpu,     riskLow,    1, CAT_APP
    .quad nameFigmaLogs,    pathFigmaLogs,    riskLow,    1, CAT_APP
    .quad nameObsidianCache,pathObsidianCache,riskLow,    1, CAT_APP
    .quad nameObsidianCode, pathObsidianCode, riskLow,    1, CAT_APP
    .quad nameObsidianGpu,  pathObsidianGpu,  riskLow,    1, CAT_APP
    .quad nameObsidianLogs, pathObsidianLogs, riskLow,    1, CAT_APP
    .quad nameWeComData,    pathWeComData,    riskHigh,   1, CAT_CHAT
    .quad nameTencentMeeting,pathTencentMeeting,riskHigh,  1, CAT_CHAT
    .quad nameBaiduNetdisk, pathBaiduNetdisk, riskHigh,   1, CAT_APP
    .quad nameBaiduNetdiskCache,pathBaiduNetdiskCache,riskLow,1, CAT_APP
    .quad nameBaiduNetdiskLogs,pathBaiduNetdiskLogs,riskLow,1, CAT_APP
    .quad nameThunderData,  pathThunderData,  riskHigh,   1, CAT_APP
    .quad nameThunderCache, pathThunderCache, riskLow,    1, CAT_APP
    .quad nameThunderLogs,  pathThunderLogs,  riskLow,    1, CAT_APP
    .quad nameNeteaseMusic, pathNeteaseMusic, riskLow,    1, CAT_MEDIA
    .quad nameNeteaseMusicLogs,pathNeteaseMusicLogs,riskLow,1, CAT_MEDIA
    .quad nameGithubDesktopCache, pathGithubDesktopCache, riskLow, 1, CAT_APP
    .quad nameGithubDesktopCode, pathGithubDesktopCode, riskLow, 1, CAT_APP
    .quad nameGithubDesktopGpu,pathGithubDesktopGpu,riskLow,1, CAT_APP
    .quad nameGithubDesktopLogs,pathGithubDesktopLogs,riskLow,1, CAT_APP
    .quad nameApifoxCache,  pathApifoxCache,  riskLow,    1, CAT_DEV
    .quad nameApifoxCode,   pathApifoxCode,   riskLow,    1, CAT_DEV
    .quad nameApifoxGpu,    pathApifoxGpu,    riskLow,    1, CAT_DEV
    .quad nameApifoxLogs,   pathApifoxLogs,   riskLow,    1, CAT_DEV
    .quad nameClaudeCache,  pathClaudeCache,  riskLow,    1, CAT_APP
    .quad nameClaudeCode,   pathClaudeCode,   riskLow,    1, CAT_APP
    .quad nameClaudeGpu,    pathClaudeGpu,    riskLow,    1, CAT_APP
    .quad nameClaudeLogs,   pathClaudeLogs,   riskLow,    1, CAT_APP
    .quad nameChatGptCache, pathChatGptCache, riskLow,    1, CAT_APP
    .quad nameChatGptCode,  pathChatGptCode,  riskLow,    1, CAT_APP
    .quad nameChatGptGpu,   pathChatGptGpu,   riskLow,    1, CAT_APP
    .quad nameChatGptLogs,  pathChatGptLogs,  riskLow,    1, CAT_APP
    .quad namePerplexityCache,pathPerplexityCache,riskLow,1, CAT_APP
    .quad namePerplexityCode,pathPerplexityCode,riskLow,  1, CAT_APP
    .quad namePerplexityGpu,pathPerplexityGpu,riskLow,    1, CAT_APP
    .quad nameSignalCache,  pathSignalCache,  riskLow,    1, CAT_APP
    .quad nameSignalCode,   pathSignalCode,   riskLow,    1, CAT_APP
    .quad nameSignalGpu,    pathSignalGpu,    riskLow,    1, CAT_APP
    .quad nameWhatsAppStore,pathWhatsAppStore,riskMedium, 1, CAT_CHAT
    .quad nameCanvaCache,   pathCanvaCache,   riskLow,    1, CAT_APP
    .quad nameCanvaCode,    pathCanvaCode,    riskLow,    1, CAT_APP
    .quad nameCanvaGpu,     pathCanvaGpu,     riskLow,    1, CAT_APP
    .quad nameCanvaLogs,    pathCanvaLogs,    riskLow,    1, CAT_APP
    .quad nameTyporaCache,  pathTyporaCache,  riskLow,    1, CAT_APP
    .quad nameTyporaGpu,    pathTyporaGpu,    riskLow,    1, CAT_APP
    .quad nameTyporaLogs,   pathTyporaLogs,   riskLow,    1, CAT_APP
    .quad nameMotrixCache,  pathMotrixCache,  riskLow,    1, CAT_APP
    .quad nameMotrixLogs,   pathMotrixLogs,   riskLow,    1, CAT_APP
    .quad nameDropboxCache, pathDropboxCache, riskLow,    1, CAT_APP
    .quad nameDropboxLogs,  pathDropboxLogs,  riskLow,    1, CAT_APP
    .quad nameGoogleDriveCache,pathGoogleDriveCache,riskLow,1, CAT_APP
    .quad nameGoogleDriveLogs,pathGoogleDriveLogs,riskLow,1, CAT_APP
    .quad nameGoogleDriveCrash,pathGoogleDriveCrash,riskLow,1, CAT_APP
    .quad nameMegaCache,    pathMegaCache,    riskLow,    1, CAT_APP
    .quad nameMegaLogs,     pathMegaLogs,     riskLow,    1, CAT_APP
    .quad nameBoxDriveCache,pathBoxDriveCache,riskLow,    1, CAT_APP
    .quad nameBoxDriveLogs, pathBoxDriveLogs, riskLow,    1, CAT_APP
    .quad nameSyncthingLogs,pathSyncthingLogs,riskLow,    1, CAT_APP
    .quad nameTianyiCloudCache,pathTianyiCloudCache,riskLow,1, CAT_APP
    .quad nameTianyiCloudLogs,pathTianyiCloudLogs,riskLow,1, CAT_APP
    .quad nameCaiyunCache,  pathCaiyunCache,  riskLow,    1, CAT_APP
    .quad nameCaiyunLogs,   pathCaiyunLogs,   riskLow,    1, CAT_APP
    .quad nameAliyunDriveCache,pathAliyunDriveCache,riskLow,1, CAT_APP
    .quad nameAliyunDriveLogs,pathAliyunDriveLogs,riskLow,1, CAT_APP
    .quad nameQuarkDriveCache,pathQuarkDriveCache,riskLow,1, CAT_APP
    .quad nameQuarkDriveLogs,pathQuarkDriveLogs,riskLow,1, CAT_APP
    .quad nameNutstoreLogs, pathNutstoreLogs, riskLow,    1, CAT_APP
    .quad nameNutstoreCache,pathNutstoreCache,riskLow,    1, CAT_APP
    .quad nameIDMLogs,      pathIDMLogs,      riskLow,    1, CAT_APP
    .quad nameQBittorrentLogs,pathQBittorrentLogs,riskLow,1, CAT_APP
    .quad nameEverythingLogs,pathEverythingLogs,riskLow,  1, CAT_APP
    .quad nameEverythingTemp,pathEverythingTemp,riskLow,  1, CAT_APP
    .quad nameToDeskLogs,   pathToDeskLogs,   riskLow,    1, CAT_APP
    .quad nameSunloginLogs, pathSunloginLogs, riskLow,    1, CAT_APP
    .quad nameSogouPyLogs,  pathSogouPyLogs,  riskLow,    1, CAT_APP
    .quad nameSogouPyTemp,  pathSogouPyTemp,  riskLow,    1, CAT_APP
    .quad nameQQPinyinLogs, pathQQPinyinLogs, riskLow,    1, CAT_APP
    .quad nameQQPinyinCache,pathQQPinyinCache,riskLow,    1, CAT_APP
    .quad nameDingTalkLocalCache,pathDingTalkLocalCache,riskLow,1, CAT_APP
    .quad nameDingTalkLogs, pathDingTalkLogs, riskLow,    1, CAT_APP
    .quad nameDingTalkCode, pathDingTalkCode, riskLow,    1, CAT_APP
    .quad nameDingTalkGpu,  pathDingTalkGpu,  riskLow,    1, CAT_APP
    .quad nameDingTalkCrash,pathDingTalkCrash,riskLow,    1, CAT_APP
    .quad nameFeishuLogs,   pathFeishuLogs,   riskLow,    1, CAT_APP
    .quad nameFeishuCode,   pathFeishuCode,   riskLow,    1, CAT_APP
    .quad nameFeishuGpu,    pathFeishuGpu,    riskLow,    1, CAT_APP
    .quad nameFeishuLocalCache,pathFeishuLocalCache,riskLow,1, CAT_APP
    .quad nameFeishuCrash,  pathFeishuCrash,  riskLow,    1, CAT_APP
    .quad nameLarkLogs,     pathLarkLogs,     riskLow,    1, CAT_APP
    .quad nameLarkCode,     pathLarkCode,     riskLow,    1, CAT_APP
    .quad nameLarkGpu,      pathLarkGpu,      riskLow,    1, CAT_APP
    .quad nameLarkCrash,    pathLarkCrash,    riskLow,    1, CAT_APP
    .quad nameWpsLogs,      pathWpsLogs,      riskLow,    1, CAT_APP
    .quad nameWpsTemp,      pathWpsTemp,      riskLow,    1, CAT_APP
    .quad nameWpsCloudCache,pathWpsCloudCache,riskLow,    1, CAT_APP
    .quad nameWpsLocalCache,pathWpsLocalCache,riskLow,    1, CAT_APP
    .quad nameWpsCrash,     pathWpsCrash,     riskLow,    1, CAT_APP
    .quad nameKingsoftPdfCache,pathKingsoftPdfCache,riskLow,1, CAT_APP
    .quad nameTencentDocsCache,pathTencentDocsCache,riskLow,1, CAT_APP
    .quad nameTencentDocsLogs,pathTencentDocsLogs,riskLow,1, CAT_APP
    .quad nameTencentDocsGpu,pathTencentDocsGpu,riskLow,  1, CAT_APP
    .quad nameTencentDocsCrash,pathTencentDocsCrash,riskLow,1, CAT_APP
    .quad nameBaiduNetdiskLocalCache,pathBaiduNetdiskLocalCache,riskLow,1, CAT_APP
    .quad nameBaiduNetdiskCrash,pathBaiduNetdiskCrash,riskLow,1, CAT_APP
    .quad nameBaiduNetdiskGpu,pathBaiduNetdiskGpu,riskLow,1, CAT_APP
    .quad nameAliyunDriveLocalCache,pathAliyunDriveLocalCache,riskLow,1, CAT_APP
    .quad nameAliyunDriveLocalLogs,pathAliyunDriveLocalLogs,riskLow,1, CAT_APP
    .quad nameAliyunDriveGpu,pathAliyunDriveGpu,riskLow,  1, CAT_APP
    .quad nameAliyunDriveCode,pathAliyunDriveCode,riskLow,1, CAT_APP
    .quad nameAliyunDriveCrash,pathAliyunDriveCrash,riskLow,1, CAT_APP
    .quad nameQuarkDriveLocalCache,pathQuarkDriveLocalCache,riskLow,1, CAT_APP
    .quad nameQuarkDriveGpu,pathQuarkDriveGpu,riskLow,   1, CAT_APP
    .quad nameQuarkDriveCode,pathQuarkDriveCode,riskLow,  1, CAT_APP
    .quad nameQuarkDriveCrash,pathQuarkDriveCrash,riskLow,1, CAT_APP
    .quad nameDrive115Cache,pathDrive115Cache,riskLow,   1, CAT_APP
    .quad nameDrive115Logs, pathDrive115Logs, riskLow,   1, CAT_APP
    .quad nameThunderProfilesCache,pathThunderProfilesCache,riskLow,1, CAT_APP
    .quad nameThunderTemp,  pathThunderTemp,  riskLow,   1, CAT_APP
    .quad nameThunderBrowserCache,pathThunderBrowserCache,riskLow,1, CAT_APP
    .quad nameToDeskCache,  pathToDeskCache,  riskLow,   1, CAT_APP
    .quad nameSunloginCache,pathSunloginCache,riskLow,   1, CAT_APP
    .quad nameSunloginCrash,pathSunloginCrash,riskLow,   1, CAT_APP
    .quad nameRustdeskCache,pathRustdeskCache,riskLow,   1, CAT_APP
    .quad nameRustdeskLogs, pathRustdeskLogs, riskLow,   1, CAT_APP
    .quad nameParsecCache,  pathParsecCache,  riskLow,   1, CAT_APP
    .quad nameParsecLogs,   pathParsecLogs,   riskLow,   1, CAT_APP
    .quad nameAnyDeskLogs,  pathAnyDeskLogs,  riskLow,   1, CAT_APP
    .quad nameTeamViewerLogs,pathTeamViewerLogs,riskLow, 1, CAT_APP
    .quad nameUToolsCache,  pathUToolsCache,  riskLow,   1, CAT_APP
    .quad nameUToolsCode,   pathUToolsCode,   riskLow,   1, CAT_APP
    .quad nameUToolsLogs,   pathUToolsLogs,   riskLow,   1, CAT_APP
    .quad nameSnipasteCache,pathSnipasteCache,riskLow,   1, CAT_APP
    .quad nameSnipasteLogs, pathSnipasteLogs, riskLow,   1, CAT_APP
    .quad namePicGoCache,   pathPicGoCache,   riskLow,   1, CAT_APP
    .quad namePicGoLogs,    pathPicGoLogs,    riskLow,   1, CAT_APP
    .quad nameClashWinLogs, pathClashWinLogs, riskLow,   1, CAT_APP
    .quad nameClashVergeLogs,pathClashVergeLogs,riskLow, 1, CAT_APP
    .quad nameClashVergeCache,pathClashVergeCache,riskLow,1, CAT_APP
    .quad nameV2rayNLogs,   pathV2rayNLogs,   riskLow,   1, CAT_APP
    .quad nameNetchLogs,    pathNetchLogs,    riskLow,   1, CAT_APP
    .quad nameBaiduPinyinLogs,pathBaiduPinyinLogs,riskLow,1, CAT_APP
    .quad nameBaiduPinyinTemp,pathBaiduPinyinTemp,riskLow,1, CAT_APP
    .quad nameIflyImeLogs,  pathIflyImeLogs,  riskLow,   1, CAT_APP
    .quad nameIflyImeTemp,  pathIflyImeTemp,  riskLow,   1, CAT_APP
    .quad nameTencentLemonLogs,pathTencentLemonLogs,riskLow,1, CAT_APP
    .quad nameTencentLemonCache,pathTencentLemonCache,riskLow,1, CAT_APP
    .quad nameHuorongLogs,  pathHuorongLogs,  riskLow,   1, CAT_APP
    .quad nameHuorongTemp,  pathHuorongTemp,  riskLow,   1, CAT_APP
    .quad nameZip360Cache,  pathZip360Cache,  riskLow,   1, CAT_APP
    .quad nameZip360Temp,   pathZip360Temp,   riskLow,   1, CAT_APP
    .quad nameTencentPcMgrLogs,pathTencentPcMgrLogs,riskLow,1, CAT_APP
    .quad nameTencentPcMgrCache,pathTencentPcMgrCache,riskLow,1, CAT_APP
    .quad nameTencentPcMgrTemp,pathTencentPcMgrTemp,riskLow,1, CAT_APP
    .quad nameSecurity360Logs,pathSecurity360Logs,riskLow,1, CAT_APP
    .quad nameSecurity360Cache,pathSecurity360Cache,riskLow,1, CAT_APP
    .quad nameSecurity360Temp,pathSecurity360Temp,riskLow,1, CAT_APP
    .quad nameSecurity360sdLogs,pathSecurity360sdLogs,riskLow,1, CAT_APP
    .quad nameSecurity360sdCache,pathSecurity360sdCache,riskLow,1, CAT_APP
    .quad nameSecurity360Downloads,pathSecurity360Downloads,riskLow,1, CAT_APP
    .quad nameLudashiLogs,  pathLudashiLogs,  riskLow,   1, CAT_APP
    .quad nameLudashiCache, pathLudashiCache, riskLow,   1, CAT_APP
    .quad nameLudashiTemp,  pathLudashiTemp,  riskLow,   1, CAT_APP
    .quad nameDriverGeniusLogs,pathDriverGeniusLogs,riskLow,1, CAT_APP
    .quad nameDriverGeniusCache,pathDriverGeniusCache,riskLow,1, CAT_APP
    .quad nameDriverBoosterCNCache,pathDriverBoosterCNCache,riskLow,1, CAT_APP
    .quad nameLenovoPcMgrLogs,pathLenovoPcMgrLogs,riskLow,1, CAT_APP
    .quad nameLenovoPcMgrCache,pathLenovoPcMgrCache,riskLow,1, CAT_APP
    .quad nameHuaweiPcMgrLogs,pathHuaweiPcMgrLogs,riskLow,1, CAT_APP
    .quad nameHuaweiPcMgrCache,pathHuaweiPcMgrCache,riskLow,1, CAT_APP
    .quad nameXiaomiPcSuiteCache,pathXiaomiPcSuiteCache,riskLow,1, CAT_APP
    .quad nameXiaomiPcSuiteLogs,pathXiaomiPcSuiteLogs,riskLow,1, CAT_APP
    .quad nameHuaweiMobileAssistantCache,pathHuaweiMobileAssistantCache,riskLow,1, CAT_APP
    .quad nameHuaweiMobileAssistantLogs,pathHuaweiMobileAssistantLogs,riskLow,1, CAT_APP
    .quad nameYoudaoDictCache,pathYoudaoDictCache,riskLow,1, CAT_APP
    .quad nameYoudaoDictLogs,pathYoudaoDictLogs,riskLow,1, CAT_APP
    .quad nameYoudaoNoteCache,pathYoudaoNoteCache,riskLow,1, CAT_APP
    .quad nameYoudaoNoteLogs,pathYoudaoNoteLogs,riskLow,1, CAT_APP
    .quad nameYinxiangCache,pathYinxiangCache,riskLow,   1, CAT_APP
    .quad nameYinxiangLogs, pathYinxiangLogs, riskLow,   1, CAT_APP
    .quad nameBaiduHiCache, pathBaiduHiCache, riskLow,   1, CAT_APP
    .quad nameBaiduHiLogs,  pathBaiduHiLogs,  riskLow,   1, CAT_APP
    .quad nameQianniuCache, pathQianniuCache, riskLow,   1, CAT_APP
    .quad nameQianniuLogs,  pathQianniuLogs,  riskLow,   1, CAT_APP
    .quad nameYuqueCache,   pathYuqueCache,   riskLow,   1, CAT_APP
    .quad nameYuqueLogs,    pathYuqueLogs,    riskLow,   1, CAT_APP
    .quad nameXMindCNCache, pathXMindCNCache, riskLow,   1, CAT_APP
    .quad nameXMindCNLogs,  pathXMindCNLogs,  riskLow,   1, CAT_APP
    .quad nameFoxmailCache, pathFoxmailCache, riskLow,   1, CAT_APP
    .quad nameFoxmailLogs,  pathFoxmailLogs,  riskLow,   1, CAT_APP
    .quad nameAliWangwangCache,pathAliWangwangCache,riskLow,1, CAT_APP
    .quad nameAliWangwangLogs,pathAliWangwangLogs,riskLow,1, CAT_APP
    .quad nameClassInCache, pathClassInCache, riskLow,   1, CAT_APP
    .quad nameClassInLogs,  pathClassInLogs,  riskLow,   1, CAT_APP
    .quad nameTencentClassroomCache,pathTencentClassroomCache,riskLow,1, CAT_APP
    .quad nameTencentClassroomLogs,pathTencentClassroomLogs,riskLow,1, CAT_APP
    .quad nameChaoxingCache,pathChaoxingCache,riskLow,   1, CAT_APP
    .quad nameChaoxingLogs, pathChaoxingLogs, riskLow,   1, CAT_APP
    .quad nameSeewoCache,   pathSeewoCache,   riskLow,   1, CAT_APP
    .quad nameSeewoLogs,    pathSeewoLogs,    riskLow,   1, CAT_APP
    .quad nameYoudaoCourseCache,pathYoudaoCourseCache,riskLow,1, CAT_APP
    .quad nameYoudaoCourseLogs,pathYoudaoCourseLogs,riskLow,1, CAT_APP
    .quad nameLanhuCache,   pathLanhuCache,   riskLow,   1, CAT_APP
    .quad nameLanhuLogs,    pathLanhuLogs,    riskLow,   1, CAT_APP
    .quad namePixsoCache,   pathPixsoCache,   riskLow,   1, CAT_APP
    .quad namePixsoCode,    pathPixsoCode,    riskLow,   1, CAT_APP
    .quad nameMasterGoCache,pathMasterGoCache,riskLow,   1, CAT_APP
    .quad nameMasterGoCode, pathMasterGoCode, riskLow,   1, CAT_APP
    .quad nameEastMoneyCache,pathEastMoneyCache,riskLow, 1, CAT_APP
    .quad nameEastMoneyLogs,pathEastMoneyLogs,riskLow,   1, CAT_APP
    .quad nameTongHuaShunCache,pathTongHuaShunCache,riskLow,1, CAT_APP
    .quad nameTongHuaShunLogs,pathTongHuaShunLogs,riskLow,1, CAT_APP
    .quad nameTencentYuanbaoCache,pathTencentYuanbaoCache,riskLow,1, CAT_APP
    .quad nameTencentYuanbaoCode,pathTencentYuanbaoCode,riskLow,1, CAT_APP
    .quad nameTencentYuanbaoGpu,pathTencentYuanbaoGpu,riskLow,1, CAT_APP
    .quad nameTencentYuanbaoLogs,pathTencentYuanbaoLogs,riskLow,1, CAT_APP
    .quad nameKimiCache,    pathKimiCache,    riskLow,   1, CAT_APP
    .quad nameKimiCode,     pathKimiCode,     riskLow,   1, CAT_APP
    .quad nameKimiGpu,      pathKimiGpu,      riskLow,   1, CAT_APP
    .quad nameKimiLogs,     pathKimiLogs,     riskLow,   1, CAT_APP
    .quad nameBaiduComateCache,pathBaiduComateCache,riskLow,1, CAT_APP
    .quad nameBaiduComateLogs,pathBaiduComateLogs,riskLow,1, CAT_APP
    .quad nameEdrawMaxCache,pathEdrawMaxCache,riskLow,   1, CAT_APP
    .quad nameEdrawMaxLogs, pathEdrawMaxLogs, riskLow,   1, CAT_APP
    .quad nameMindMasterCache,pathMindMasterCache,riskLow,1, CAT_APP
    .quad nameMindMasterLogs,pathMindMasterLogs,riskLow,  1, CAT_APP
    .quad nameMubuCache,    pathMubuCache,    riskLow,   1, CAT_APP
    .quad nameMubuLogs,     pathMubuLogs,     riskLow,   1, CAT_APP
    .quad nameNeteaseMailCache,pathNeteaseMailCache,riskLow,1, CAT_APP
    .quad nameNeteaseMailLogs,pathNeteaseMailLogs,riskLow,1, CAT_APP
    .quad nameYoudaoTranslateCache,pathYoudaoTranslateCache,riskLow,1, CAT_APP
    .quad nameYoudaoTranslateLogs,pathYoudaoTranslateLogs,riskLow,1, CAT_APP
    .quad nameTickTickCache,pathTickTickCache,riskLow,   1, CAT_APP
    .quad nameTickTickLogs, pathTickTickLogs, riskLow,   1, CAT_APP
    .quad nameJoplinCache,  pathJoplinCache,  riskLow,   1, CAT_APP
    .quad nameJoplinLogs,   pathJoplinLogs,   riskLow,   1, CAT_APP
    .quad nameZoteroCache,  pathZoteroCache,  riskLow,   1, CAT_APP
    .quad nameEvernoteCache,pathEvernoteCache,riskLow,   1, CAT_APP
    .quad nameEvernoteLogs, pathEvernoteLogs, riskLow,   1, CAT_APP
    .quad nameAdobeCcCache, pathAdobeCcCache, riskLow,   1, CAT_APP
    .quad nameAdobeCcLogs,  pathAdobeCcLogs,  riskLow,   1, CAT_APP
    .quad nameThunderbirdCache,pathThunderbirdCache,riskLow,1, CAT_APP
    .quad nameThunderbirdLogs,pathThunderbirdLogs,riskLow,1, CAT_APP
    .quad nameMailspringCache,pathMailspringCache,riskLow,1, CAT_APP
    .quad nameMailspringLogs,pathMailspringLogs,riskLow,1, CAT_APP
    .quad nameTodoistCache,pathTodoistCache,riskLow,     1, CAT_APP
    .quad nameTodoistCode, pathTodoistCode, riskLow,     1, CAT_APP
    .quad nameTodoistLogs, pathTodoistLogs, riskLow,     1, CAT_APP
    .quad nameTrelloCache, pathTrelloCache, riskLow,     1, CAT_APP
    .quad nameTrelloCode,  pathTrelloCode,  riskLow,     1, CAT_APP
    .quad nameMiroCache,   pathMiroCache,   riskLow,     1, CAT_APP
    .quad nameMiroCode,    pathMiroCode,    riskLow,     1, CAT_APP
    .quad nameLinearCache, pathLinearCache, riskLow,     1, CAT_APP
    .quad nameLinearCode,  pathLinearCode,  riskLow,     1, CAT_APP
    .quad namePowerToysLogs,pathPowerToysLogs,riskLow,    1, CAT_APP
    .quad nameOneDriveLogs, pathOneDriveLogs, riskLow,    1, CAT_APP
    .quad nameOfficeCache,  pathOfficeCache,  riskLow,    1, CAT_APP
    .quad nameOutlookTemp,  pathOutlookTemp,  riskLow,    1, CAT_APP
    .quad nameQQMusicCache, pathQQMusicCache, riskLow,    1, CAT_MEDIA
    .quad nameQQMusicLocal, pathQQMusicLocal, riskLow,    1, CAT_MEDIA
    .quad nameTencentVideo, pathTencentVideo, riskLow,    1, CAT_MEDIA
    .quad nameTencentVideoCache,pathTencentVideoCache,riskLow,1, CAT_MEDIA
    .quad nameIqiyiCache,   pathIqiyiCache,   riskLow,    1, CAT_MEDIA
    .quad nameIqiyiLocal,   pathIqiyiLocal,   riskLow,    1, CAT_MEDIA
    .quad nameBilibiliCache,pathBilibiliCache,riskLow,    1, CAT_MEDIA
    .quad nameBilibiliLogs, pathBilibiliLogs, riskLow,    1, CAT_MEDIA
    .quad namePotPlayerCache,pathPotPlayerCache,riskLow,  1, CAT_MEDIA
    .quad nameWeChatFiles,  pathWeChatFiles,  riskHigh,   1, CAT_CHAT
    .quad nameTencentFiles, pathTencentFiles, riskHigh,   1, CAT_CHAT
    .quad nameQQEimFiles,   pathQQEimFiles,   riskHigh,   1, CAT_CHAT
    .quad nameWeChatAppData,pathWeChatAppData,riskHigh,   1, CAT_CHAT
    .quad nameQQAppData,    pathQQAppData,    riskHigh,   1, CAT_CHAT
    .quad nameQQNTData,     pathQQNTData,     riskHigh,   1, CAT_CHAT
    .quad nameWeChatLogs,   pathWeChatLogs,   riskLow,    1, CAT_CHAT
    .quad nameWeChatXPluginLogs,pathWeChatXPluginLogs,riskLow,1, CAT_CHAT
    .quad nameWeChatCefCache,pathWeChatCefCache,riskLow,  1, CAT_CHAT
    .quad nameQQNTCache,    pathQQNTCache,    riskLow,    1, CAT_CHAT
    .quad nameQQNTGpu,      pathQQNTGpu,      riskLow,    1, CAT_CHAT
    .quad nameQQNTLogs,     pathQQNTLogs,     riskLow,    1, CAT_CHAT
    .quad nameQQNTCrashpad, pathQQNTCrashpad, riskLow,    1, CAT_CHAT
    .quad nameTIMLogs,      pathTIMLogs,      riskLow,    1, CAT_CHAT
    .quad nameTIMCache,     pathTIMCache,     riskLow,    1, CAT_CHAT
    .quad nameQQGuildCache, pathQQGuildCache, riskLow,    1, CAT_CHAT
    .quad nameQQGuildLogs,  pathQQGuildLogs,  riskLow,    1, CAT_CHAT
    .quad nameWeComCache,   pathWeComCache,   riskLow,    1, CAT_CHAT
    .quad nameWeComLogs,    pathWeComLogs,    riskLow,    1, CAT_CHAT
    .quad nameWeComGpu,     pathWeComGpu,     riskLow,    1, CAT_CHAT
    .quad nameWeComCrash,   pathWeComCrash,   riskLow,    1, CAT_CHAT
    .quad nameTencentMeetingLogs,pathTencentMeetingLogs,riskLow,1, CAT_CHAT
    .quad nameTencentMeetingCache,pathTencentMeetingCache,riskLow,1, CAT_CHAT
    .quad nameTencentMeetingGpu,pathTencentMeetingGpu,riskLow,1, CAT_CHAT
    .quad nameTencentMeetingCrash,pathTencentMeetingCrash,riskLow,1, CAT_CHAT
    .quad nameWeChatDevToolsCache,pathWeChatDevToolsCache,riskLow,1, CAT_DEV
    .quad nameWeChatDevToolsCode,pathWeChatDevToolsCode,riskLow,1, CAT_DEV
    .quad nameWeChatDevToolsLogs,pathWeChatDevToolsLogs,riskLow,1, CAT_DEV
    .quad nameWeChatDevToolsGpu,pathWeChatDevToolsGpu,riskLow,1, CAT_DEV
    .quad nameHBuilderXCache,pathHBuilderXCache,riskLow, 1, CAT_DEV
    .quad nameHBuilderXCode,pathHBuilderXCode,riskLow,   1, CAT_DEV
    .quad nameHBuilderXGpu, pathHBuilderXGpu, riskLow,   1, CAT_DEV
    .quad nameHBuilderXLogs,pathHBuilderXLogs,riskLow,   1, CAT_DEV
    .quad nameDevEcoCache,  pathDevEcoCache,  riskLow,   1, CAT_DEV
    .quad nameDevEcoLogs,   pathDevEcoLogs,   riskLow,   1, CAT_DEV
    .quad nameTaroCache,    pathTaroCache,    riskLow,   1, CAT_DEV
    .quad nameUniappCache,  pathUniappCache,  riskLow,   1, CAT_DEV
    .quad nameNpm,          pathNpm,          riskLow,    1, CAT_DEV
    .quad nameNpmLocal,     pathNpmLocal,     riskLow,    1, CAT_DEV
    .quad namePip,          pathPip,          riskLow,    1, CAT_DEV
    .quad nameNuget,        pathNuget,        riskHigh,   1, CAT_DEV
    .quad nameGradle,       pathGradle,       riskLow,    1, CAT_DEV
    .quad nameGradleWrapper,pathGradleWrapper,riskLow,    1, CAT_DEV
    .quad nameGradleDaemon, pathGradleDaemon, riskLow,    1, CAT_DEV
    .quad nameGradleNative, pathGradleNative, riskLow,    1, CAT_DEV
    .quad nameGradleBuildOutput,pathGradleBuildOutput,riskLow, 1, CAT_DEV
    .quad nameFabricLoom,   pathFabricLoom,   riskLow,    1, CAT_DEV
    .quad nameFabricMinecraft,pathFabricMinecraft,riskLow,1, CAT_DEV
    .quad nameForgeGradle,  pathForgeGradle,  riskLow,    1, CAT_DEV
    .quad nameNeoForgeGradle,pathNeoForgeGradle,riskLow,  1, CAT_DEV
    .quad nameQuiltLoom,    pathQuiltLoom,    riskLow,    1, CAT_DEV
    .quad nameArchitecturyLoom,pathArchitecturyLoom,riskLow,1, CAT_DEV
    .quad namePaperweight,  pathPaperweight,  riskLow,    1, CAT_DEV
    .quad nameMcDevCache,   pathMcDevCache,   riskLow,    1, CAT_DEV
    .quad nameMaven,        pathMaven,        riskMedium, 1, CAT_DEV
    .quad nameMavenWrapper, pathMavenWrapper, riskLow,    1, CAT_DEV
    .quad nameYarn,         pathYarn,         riskLow,    1, CAT_DEV
    .quad nameYarnBerry,    pathYarnBerry,    riskLow,    1, CAT_DEV
    .quad namePnpm,         pathPnpm,         riskLow,    1, CAT_DEV
    .quad nameCargo,        pathCargo,        riskLow,    1, CAT_DEV
    .quad nameGoBuild,      pathGoBuild,      riskLow,    1, CAT_DEV
    .quad nameDockerDesktop,pathDockerDesktop,riskHigh,   0, CAT_DEV
    .quad nameDockerDesktopLogs,pathDockerDesktopLogs,riskLow,1, CAT_DEV
    .quad namePoetryCache,  pathPoetryCache,  riskLow,    1, CAT_DEV
    .quad nameAndroidBuild, pathAndroidBuild, riskLow,    1, CAT_DEV
    .quad nameUvCache,      pathUvCache,      riskLow,    1, CAT_DEV
    .quad nameCondaPkgs,    pathCondaPkgs,    riskMedium, 1, CAT_DEV
    .quad nameHuggingFace,  pathHuggingFace,  riskMedium, 1, CAT_DEV
    .quad nameCursorCache,  pathCursorCache,  riskLow,    1, CAT_DEV
    .quad nameCursorData,   pathCursorData,   riskLow,    1, CAT_DEV
    .quad nameWindsurfCache,pathWindsurfCache,riskLow,    1, CAT_DEV
    .quad nameTraeCache,    pathTraeCache,    riskLow,    1, CAT_DEV
    .quad nameJetBrainsLocal,pathJetBrainsLocal,riskMedium,1, CAT_DEV
    .quad nameJetBrainsToolboxCache,pathJetBrainsToolboxCache,riskLow,1, CAT_DEV
    .quad nameJetBrainsToolboxLogs,pathJetBrainsToolboxLogs,riskLow,1, CAT_DEV
    .quad nameVsCache,      pathVsCache,      riskMedium, 1, CAT_DEV
    .quad nameVsCodeCachedData,pathVsCodeCachedData,riskLow,1, CAT_DEV
    .quad nameVsCodeUserLogs,pathVsCodeUserLogs,riskLow,  1, CAT_DEV
    .quad nameNodeGyp,      pathNodeGyp,      riskLow,    1, CAT_DEV
    .quad nameElectronCache,pathElectronCache,riskLow,    1, CAT_DEV
    .quad namePlaywright,   pathPlaywright,   riskLow,    1, CAT_DEV
    .quad nameSelenium,     pathSelenium,     riskLow,    1, CAT_DEV
    .quad nameTorchCache,   pathTorchCache,   riskMedium, 1, CAT_DEV
    .quad namePreCommit,    pathPreCommit,    riskLow,    1, CAT_DEV
    .quad nameGoModCache,   pathGoModCache,   riskLow,    1, CAT_DEV
    .quad nameRustGit,      pathRustGit,      riskLow,    1, CAT_DEV
    .quad nameVcpkgDownloads,pathVcpkgDownloads,riskLow,  1, CAT_DEV
    .quad nameConanCache,   pathConanCache,   riskMedium, 1, CAT_DEV
    .quad nameComposerCache,pathComposerCache,riskLow,    1, CAT_DEV
    .quad nameRubyGemCache, pathRubyGemCache, riskLow,    1, CAT_DEV
    .quad namePubCache,     pathPubCache,     riskLow,    1, CAT_DEV
    .quad nameDotnetHttp,   pathDotnetHttp,   riskLow,    1, CAT_DEV
    .quad nameBunCache,     pathBunCache,     riskLow,    1, CAT_DEV
    .quad nameDenoCache,    pathDenoCache,    riskLow,    1, CAT_DEV
    .quad nameRuffCache,    pathRuffCache,    riskLow,    1, CAT_DEV
    .quad nameMypyCache,    pathMypyCache,    riskLow,    1, CAT_DEV
    .quad nameCcache,       pathCcache,       riskLow,    1, CAT_DEV
    .quad nameNinjaCache,   pathNinjaCache,   riskLow,    1, CAT_DEV
    .quad nameGitKrakenCache,pathGitKrakenCache,riskLow,  1, CAT_DEV
    .quad nameGitKrakenGpu, pathGitKrakenGpu, riskLow,    1, CAT_DEV
    .quad nameInsomniaCache,pathInsomniaCache,riskLow,    1, CAT_DEV
    .quad nameInsomniaCode, pathInsomniaCode, riskLow,    1, CAT_DEV
    .quad nameInsomniaGpu,  pathInsomniaGpu,  riskLow,    1, CAT_DEV
    .quad nameApiPostCache, pathApiPostCache, riskLow,    1, CAT_DEV
    .quad nameApiPostCode,  pathApiPostCode,  riskLow,    1, CAT_DEV
    .quad nameApiPostLogs,  pathApiPostLogs,  riskLow,    1, CAT_DEV
    .quad nameSourceTreeCache,pathSourceTreeCache,riskLow,1, CAT_DEV
    .quad nameSourceTreeLogs,pathSourceTreeLogs,riskLow,  1, CAT_DEV
    .quad nameTortoiseGitLogs,pathTortoiseGitLogs,riskLow,1, CAT_DEV
    .quad nameCmderCache,   pathCmderCache,   riskLow,    1, CAT_DEV
    .quad nameEmscriptenCache,pathEmscriptenCache,riskLow,1, CAT_DEV
    .quad nameLmStudioCache,pathLmStudioCache,riskLow,    1, CAT_DEV
    .quad nameLmStudioGpu,  pathLmStudioGpu,  riskLow,    1, CAT_DEV
    .quad nameOllamaLogs,   pathOllamaLogs,   riskLow,    1, CAT_DEV
    .quad nameAndroidStudioCache,pathAndroidStudioCache,riskLow,1, CAT_DEV
    .quad nameAndroidStudioLogs,pathAndroidStudioLogs,riskLow,1, CAT_DEV
    .quad nameCypressCache, pathCypressCache, riskLow,    1, CAT_DEV
    .quad nameTurboCache,   pathTurboCache,   riskLow,    1, CAT_DEV
    .quad nameViteCache,    pathViteCache,    riskLow,    1, CAT_DEV
    .quad nameExpoCache,    pathExpoCache,    riskLow,    1, CAT_DEV
    .quad namePrismaCache,  pathPrismaCache,  riskLow,    1, CAT_DEV
    .quad nameBazelCache,   pathBazelCache,   riskLow,    1, CAT_DEV
    .quad nameRustupDownloads,pathRustupDownloads,riskLow,1, CAT_DEV
    .quad nameRustupTmp,    pathRustupTmp,    riskLow,    1, CAT_DEV
    .quad namePipxCache,    pathPipxCache,    riskLow,    1, CAT_DEV
    .quad nameRyeCache,     pathRyeCache,     riskLow,    1, CAT_DEV
    .quad nameSccache,      pathSccache,      riskLow,    1, CAT_DEV
    .quad nameDockerBuildx, pathDockerBuildx, riskLow,    1, CAT_DEV
    .quad nameAndroidGradle,pathAndroidGradle,riskLow,    1, CAT_DEV
    .quad nameSteamShader,  pathSteamShader,  riskLow,    1, CAT_GAME
    .quad nameSteamHtmlCache,pathSteamHtmlCache,riskLow,  1, CAT_GAME
    .quad nameSteamAppCache,pathSteamAppCache,riskLow,    1, CAT_GAME
    .quad nameSteamDepotCache,pathSteamDepotCache,riskLow,1, CAT_GAME
    .quad nameSteamDumps,   pathSteamDumps,   riskLow,    1, CAT_GAME
    .quad nameEpicWebcache, pathEpicWebcache, riskLow,    1, CAT_GAME
    .quad nameBattlenet,    pathBattlenet,    riskLow,    1, CAT_GAME
    .quad nameBattlenetLogs,pathBattlenetLogs,riskLow,  1, CAT_GAME
    .quad nameEaDesktop,    pathEaDesktop,    riskLow,    1, CAT_GAME
    .quad nameEaLogs,       pathEaLogs,       riskLow,    1, CAT_GAME
    .quad nameUbisoftCache, pathUbisoftCache, riskLow,    1, CAT_GAME
    .quad nameUbisoftLogs,  pathUbisoftLogs,  riskLow,    1, CAT_GAME
    .quad nameRiotLogs,     pathRiotLogs,     riskLow,    1, CAT_GAME
    .quad nameRiotCrashes,  pathRiotCrashes,  riskLow,    1, CAT_GAME
    .quad nameGogWebCache,  pathGogWebCache,  riskLow,    1, CAT_GAME
    .quad nameGogLogs,      pathGogLogs,      riskLow,    1, CAT_GAME
    .quad nameRobloxLogs,   pathRobloxLogs,   riskLow,    1, CAT_GAME
    .quad nameRobloxCache,  pathRobloxCache,  riskLow,    1, CAT_GAME
    .quad nameMinecraftLogs,pathMinecraftLogs,riskLow,    1, CAT_GAME
    .quad nameMinecraftCrash,pathMinecraftCrash,riskLow,  1, CAT_GAME
    .quad nameMinecraftWebCache,pathMinecraftWebCache,riskLow,1, CAT_GAME
    .quad nameMinecraftAssetsLog,pathMinecraftAssetsLog,riskLow,1, CAT_GAME
    .quad nameModrinthCache,pathModrinthCache,riskLow,    1, CAT_GAME
    .quad nameModrinthCode, pathModrinthCode, riskLow,    1, CAT_GAME
    .quad nameCurseForgeCache,pathCurseForgeCache,riskLow,1, CAT_GAME
    .quad nameCurseForgeLogs,pathCurseForgeLogs,riskLow,  1, CAT_GAME
    .quad namePrismLogs,    pathPrismLogs,    riskLow,    1, CAT_GAME
    .quad namePrismMetaCache,pathPrismMetaCache,riskLow,  1, CAT_GAME
    .quad nameMultiMCLogs,  pathMultiMCLogs,  riskLow,    1, CAT_GAME
    .quad nameATLauncherLogs,pathATLauncherLogs,riskLow,  1, CAT_GAME
    .quad nameGDLauncherCache,pathGDLauncherCache,riskLow,1, CAT_GAME
    .quad nameMCreatorGradle,pathMCreatorGradle,riskLow,  1, CAT_DEV
    .quad nameMCreatorCache,pathMCreatorCache,riskLow,    1, CAT_DEV
    .quad nameHoYoCache,    pathHoYoCache,    riskLow,    1, CAT_GAME
    .quad nameHoYoLogs,     pathHoYoLogs,     riskLow,    1, CAT_GAME
    .quad nameHoYoGpu,      pathHoYoGpu,      riskLow,    1, CAT_GAME
    .quad nameSteamLogs,    pathSteamLogs,    riskLow,    1, CAT_GAME
    .quad nameEpicLogs,     pathEpicLogs,     riskLow,    1, CAT_GAME
    .quad nameEpicCrashes,  pathEpicCrashes,  riskLow,    1, CAT_GAME
    .quad nameRockstarLogs, pathRockstarLogs, riskLow,    1, CAT_GAME
    .quad nameFiveMCache,   pathFiveMCache,   riskLow,    1, CAT_GAME
    .quad nameXboxGamingCache,pathXboxGamingCache,riskLow,1, CAT_GAME
    .quad nameXboxAppCache, pathXboxAppCache, riskLow,    1, CAT_GAME
    .quad nameWeGameCache,  pathWeGameCache,  riskLow,    1, CAT_GAME
    .quad nameWeGameLogs,   pathWeGameLogs,   riskLow,    1, CAT_GAME
    .quad nameNeteaseUULogs,pathNeteaseUULogs,riskLow,   1, CAT_GAME
    .quad nameNeteaseUUCache,pathNeteaseUUCache,riskLow, 1, CAT_GAME
    .quad nameNeteaseUUTemp,pathNeteaseUUTemp,riskLow,   1, CAT_GAME
    .quad nameQQGameCache,  pathQQGameCache,  riskLow,    1, CAT_GAME
    .quad nameQQGameLogs,   pathQQGameLogs,   riskLow,    1, CAT_GAME
    .quad nameWeGameDownloadCache,pathWeGameDownloadCache,riskLow,1, CAT_GAME
    .quad nameWeGameWebCache,pathWeGameWebCache,riskLow,  1, CAT_GAME
    .quad nameYuanShenCache,pathYuanShenCache,riskLow,    1, CAT_GAME
    .quad nameStarRailCache,pathStarRailCache,riskLow,    1, CAT_GAME
    .quad nameNeteaseGameCache,pathNeteaseGameCache,riskLow,1, CAT_GAME
    .quad nameNeteaseGameLogs,pathNeteaseGameLogs,riskLow,1, CAT_GAME
    .quad nameMuMuLogs,     pathMuMuLogs,     riskLow,    1, CAT_GAME
    .quad nameMuMuCache,    pathMuMuCache,    riskLow,    1, CAT_GAME
    .quad nameLDPlayerLogs, pathLDPlayerLogs, riskLow,    1, CAT_GAME
    .quad nameLDPlayerCache,pathLDPlayerCache,riskLow,    1, CAT_GAME
    .quad nameLanternCache, pathLanternCache, riskLow,    1, CAT_GAME
    .quad nameLanternLogs,  pathLanternLogs,  riskLow,    1, CAT_GAME
    .quad namePlayniteCache,pathPlayniteCache,riskLow,    1, CAT_GAME
    .quad namePlayniteLogs, pathPlayniteLogs, riskLow,    1, CAT_GAME
    .quad nameHeroicCache,  pathHeroicCache,  riskLow,    1, CAT_GAME
    .quad nameHeroicLogs,   pathHeroicLogs,   riskLow,    1, CAT_GAME
    .quad nameOverwolfCache,pathOverwolfCache,riskLow,    1, CAT_GAME
    .quad nameOverwolfLogs, pathOverwolfLogs, riskLow,    1, CAT_GAME
    .quad nameItchCache,    pathItchCache,    riskLow,    1, CAT_GAME
    .quad nameItchLogs,     pathItchLogs,     riskLow,    1, CAT_GAME
    .quad nameParadoxCache, pathParadoxCache, riskLow,    1, CAT_GAME
    .quad nameParadoxLogs,  pathParadoxLogs,  riskLow,    1, CAT_GAME
    .quad nameBlueStacksLogs,pathBlueStacksLogs,riskLow,  1, CAT_GAME
    .quad nameBlueStacksCache,pathBlueStacksCache,riskLow,1, CAT_GAME
    .quad nameNoxLogs,      pathNoxLogs,      riskLow,    1, CAT_GAME
    .quad nameNoxCache,     pathNoxCache,     riskLow,    1, CAT_GAME
    .quad nameAdobeMedia,   pathAdobeMedia,   riskLow,    1, CAT_MEDIA
    .quad nameAdobeCommon,  pathAdobeCommon,  riskLow,    1, CAT_MEDIA
    .quad nameAdobePeak,    pathAdobePeak,    riskLow,    1, CAT_MEDIA
    .quad nameUnityCache,   pathUnityCache,   riskLow,    1, CAT_GAME
    .quad nameUnityAsset,   pathUnityAsset,   riskMedium, 1, CAT_GAME
    .quad nameUnityShader,  pathUnityShader,  riskLow,    1, CAT_GAME
    .quad nameUnrealDDC,    pathUnrealDDC,    riskLow,    1, CAT_GAME
    .quad nameUnrealLogs,   pathUnrealLogs,   riskLow,    1, CAT_GAME
    .quad nameEpicUnrealDDC,pathEpicUnrealDDC,riskLow,    1, CAT_GAME
    .quad nameBlenderTemp,  pathBlenderTemp,  riskLow,    1, CAT_MEDIA
    .quad nameBlenderCache, pathBlenderCache, riskLow,    1, CAT_MEDIA
    .quad nameObsLogs,      pathObsLogs,      riskLow,    1, CAT_MEDIA
    .quad nameObsCrashDumps,pathObsCrashDumps,riskLow,    1, CAT_MEDIA
    .quad nameAudacityTemp, pathAudacityTemp, riskLow,    1, CAT_MEDIA
    .quad nameShotcutCache, pathShotcutCache, riskLow,    1, CAT_MEDIA
    .quad nameKdenliveCache,pathKdenliveCache,riskLow,    1, CAT_MEDIA
    .quad nameGimpTemp,     pathGimpTemp,     riskLow,    1, CAT_MEDIA
    .quad nameInkscapeCache,pathInkscapeCache,riskLow,    1, CAT_MEDIA
    .quad nameKritaCache,   pathKritaCache,   riskLow,    1, CAT_MEDIA
    .quad namePaintDotNetTemp,pathPaintDotNetTemp,riskLow,1, CAT_MEDIA
    .quad nameShareXLogs,   pathShareXLogs,   riskLow,    1, CAT_MEDIA
    .quad nameScreenToGifTemp,pathScreenToGifTemp,riskLow,1, CAT_MEDIA
    .quad nameXnViewCache,  pathXnViewCache,  riskLow,    1, CAT_MEDIA
    .quad nameCapCutCache,  pathCapCutCache,  riskLow,    1, CAT_MEDIA
    .quad nameCapCutCode,   pathCapCutCode,   riskLow,    1, CAT_MEDIA
    .quad nameCapCutGpu,    pathCapCutGpu,    riskLow,    1, CAT_MEDIA
    .quad nameAdobeAeCache, pathAdobeAeCache, riskLow,    1, CAT_MEDIA
    .quad nameDaVinciCache, pathDaVinciCache, riskLow,    1, CAT_MEDIA
    .quad nameDaVinciLogs,  pathDaVinciLogs,  riskLow,    1, CAT_MEDIA
    .quad nameHandBrakeLogs,pathHandBrakeLogs,riskLow,    1, CAT_MEDIA
    .quad nameAimpCache,    pathAimpCache,    riskLow,    1, CAT_MEDIA
    .quad nameNeteaseMusicWebCache,pathNeteaseMusicWebCache,riskLow,1, CAT_MEDIA
    .quad nameNeteaseMusicGpu,pathNeteaseMusicGpu,riskLow,1, CAT_MEDIA
    .quad nameQQMusicLogs,  pathQQMusicLogs,  riskLow,    1, CAT_MEDIA
    .quad nameQQMusicGpu,   pathQQMusicGpu,   riskLow,    1, CAT_MEDIA
    .quad nameKugouLogs,    pathKugouLogs,    riskLow,    1, CAT_MEDIA
    .quad nameKugouTemp,    pathKugouTemp,    riskLow,    1, CAT_MEDIA
    .quad nameKuwoLogs,     pathKuwoLogs,     riskLow,    1, CAT_MEDIA
    .quad nameTencentVideoLogs,pathTencentVideoLogs,riskLow,1, CAT_MEDIA
    .quad nameTencentVideoGpu,pathTencentVideoGpu,riskLow,1, CAT_MEDIA
    .quad nameIqiyiLogs,    pathIqiyiLogs,    riskLow,    1, CAT_MEDIA
    .quad nameIqiyiGpu,     pathIqiyiGpu,     riskLow,    1, CAT_MEDIA
    .quad nameYoukuCache,   pathYoukuCache,   riskLow,    1, CAT_MEDIA
    .quad nameYoukuLogs,    pathYoukuLogs,    riskLow,    1, CAT_MEDIA
    .quad nameYoukuGpu,     pathYoukuGpu,     riskLow,    1, CAT_MEDIA
    .quad nameMangoTVCache, pathMangoTVCache, riskLow,    1, CAT_MEDIA
    .quad nameMangoTVLogs,  pathMangoTVLogs,  riskLow,    1, CAT_MEDIA
    .quad nameMangoTVGpu,   pathMangoTVGpu,   riskLow,    1, CAT_MEDIA
    .quad nameBilibiliGpu,  pathBilibiliGpu,  riskLow,    1, CAT_MEDIA
    .quad nameBilibiliCrash,pathBilibiliCrash,riskLow,    1, CAT_MEDIA
    .quad nameDouyinCache,  pathDouyinCache,  riskLow,    1, CAT_MEDIA
    .quad nameDouyinLogs,   pathDouyinLogs,   riskLow,    1, CAT_MEDIA
    .quad nameDouyinGpu,    pathDouyinGpu,    riskLow,    1, CAT_MEDIA
    .quad nameDouyinCrash,  pathDouyinCrash,  riskLow,    1, CAT_MEDIA
    .quad nameJianyingCache,pathJianyingCache,riskLow,    1, CAT_MEDIA
    .quad nameJianyingCode, pathJianyingCode, riskLow,    1, CAT_MEDIA
    .quad nameJianyingGpu,  pathJianyingGpu,  riskLow,    1, CAT_MEDIA
    .quad nameJianyingLogs, pathJianyingLogs, riskLow,    1, CAT_MEDIA
    .quad nameHuyaCache,    pathHuyaCache,    riskLow,    1, CAT_MEDIA
    .quad nameHuyaLogs,     pathHuyaLogs,     riskLow,    1, CAT_MEDIA
    .quad nameDouyuCache,   pathDouyuCache,   riskLow,    1, CAT_MEDIA
    .quad nameDouyuLogs,    pathDouyuLogs,    riskLow,    1, CAT_MEDIA
    .quad nameKuaishouCache,pathKuaishouCache,riskLow,    1, CAT_MEDIA
    .quad nameKuaishouLogs, pathKuaishouLogs, riskLow,    1, CAT_MEDIA
    .quad nameKuaishouGpu,  pathKuaishouGpu,  riskLow,    1, CAT_MEDIA
    .quad nameKuaishouCrash,pathKuaishouCrash,riskLow,    1, CAT_MEDIA
    .quad nameXimalayaCache,pathXimalayaCache,riskLow,    1, CAT_MEDIA
    .quad nameXimalayaLogs, pathXimalayaLogs, riskLow,    1, CAT_MEDIA
    .quad nameLizhiCache,   pathLizhiCache,   riskLow,    1, CAT_MEDIA
    .quad nameLizhiLogs,    pathLizhiLogs,    riskLow,    1, CAT_MEDIA
    .quad nameBaiduMusicCache,pathBaiduMusicCache,riskLow,1, CAT_MEDIA
    .quad nameBaiduMusicLogs,pathBaiduMusicLogs,riskLow,  1, CAT_MEDIA
    .quad nameSohuVideoCache,pathSohuVideoCache,riskLow,  1, CAT_MEDIA
    .quad nameSohuVideoLogs,pathSohuVideoLogs,riskLow,    1, CAT_MEDIA
    .quad namePptvCache,    pathPptvCache,    riskLow,    1, CAT_MEDIA
    .quad namePptvLogs,     pathPptvLogs,     riskLow,    1, CAT_MEDIA
    .quad nameAcFunCache,   pathAcFunCache,   riskLow,    1, CAT_MEDIA
    .quad nameAcFunLogs,    pathAcFunLogs,    riskLow,    1, CAT_MEDIA
    .quad nameVlcArtCache,  pathVlcArtCache,  riskLow,    1, CAT_MEDIA
    .quad nameKugouCache,   pathKugouCache,   riskLow,    1, CAT_MEDIA
    .quad nameKuwoCache,    pathKuwoCache,    riskLow,    1, CAT_MEDIA
    .quad nameFoobarCache,  pathFoobarCache,  riskLow,    1, CAT_MEDIA
    .quad nameFoobarLogs,   pathFoobarLogs,   riskLow,    1, CAT_MEDIA
    .quad nameMpvCache,     pathMpvCache,     riskLow,    1, CAT_MEDIA
    .quad nameClipchampCache,pathClipchampCache,riskLow,  1, CAT_MEDIA
    .quad nameFilmoraCache, pathFilmoraCache, riskLow,    1, CAT_MEDIA
    .quad nameFilmoraLogs,  pathFilmoraLogs,  riskLow,    1, CAT_MEDIA
    .quad nameMovaviCache,  pathMovaviCache,  riskLow,    1, CAT_MEDIA
    .quad nameCamtasiaCache,pathCamtasiaCache,riskLow,    1, CAT_MEDIA
    .quad nameSnagitCache,  pathSnagitCache,  riskLow,    1, CAT_MEDIA
    .quad nameNvidiaDownloader,pathNvidiaDownloader,riskLow,1, CAT_WINDOWS
    .quad nameNvidiaGfeCef, pathNvidiaGfeCef, riskLow,    1, CAT_APP
    .quad 0, 0, 0, 0, 0

.section .bss
.align 8
hInstance:   .skip 8
hMain:       .skip 8
hWorker:     .skip 8
hwndScan:    .skip 8
hwndDryRun:  .skip 8
hwndClean:   .skip 8
hwndStop:    .skip 8
hwndProgress:.skip 8
hwndCatWindows:.skip 8
hwndCatBrowser:.skip 8
hwndCatApp:  .skip 8
hwndCatDev:  .skip 8
hwndCatChat: .skip 8
hwndCatGame: .skip 8
hwndCatMedia:.skip 8
hwndCatRecycle:.skip 8
hwndLog:     .skip 8
hUiFont:     .skip 8
logPos:      .skip 8
threadId:    .skip 4
workerMode:  .skip 4
targetExists:.skip 4
targetAttrs: .skip 4
targetCleanDefault:.skip 8
targetCategory:.skip 8
scanCancel:  .skip 8
progressDone:.skip 8
progressTotal:.skip 8
progressPos: .skip 8
catWindowsSelected:.skip 8
catBrowserSelected:.skip 8
catAppSelected:.skip 8
catDevSelected:.skip 8
catChatSelected:.skip 8
catGameSelected:.skip 8
catMediaSelected:.skip 8
catRecycleSelected:.skip 8
scanBytes:   .skip 8
scanFiles:   .skip 8
scanDirs:    .skip 8
scanSkipped: .skip 8
scanVisited: .skip 8
scanTruncated:.skip 8
cleanFiles:  .skip 8
cleanDirs:   .skip 8
cleanFailed: .skip 8
cleanSkipped:.skip 8
totalExistingTargets:.skip 8
totalMissingTargets:.skip 8
totalScanBytes:.skip 8
totalScanFiles:.skip 8
totalScanDirs:.skip 8
totalScanSkipped:.skip 8
totalTruncatedTargets:.skip 8
totalCleanFiles:.skip 8
totalCleanDirs:.skip 8
totalCleanFailed:.skip 8
totalCleanSkipped:.skip 8
totalCleanSkippedTargets:.skip 8
hDebugLog:   .skip 8
wc:          .skip 80
msg:         .skip 64
debugLogTime:.skip 16
debugLogPathW:.skip 2048
classNameW:       .skip 256
appTitleW:        .skip 256
buttonClassW:     .skip 64
editClassW:       .skip 64
staticClassW:     .skip 64
emptyStringW:     .skip 8
fontFaceW:        .skip 128
scanButtonTextW:  .skip 128
dryRunButtonTextW:.skip 128
cleanButtonTextW: .skip 128
progressIdleTextW:.skip 256
catWindowsTextW: .skip 128
catBrowserTextW: .skip 128
catAppTextW:     .skip 128
catDevTextW:     .skip 128
catChatTextW:    .skip 128
catGameTextW:    .skip 128
catMediaTextW:   .skip 128
catRecycleTextW: .skip 128
stopButtonTextW:  .skip 128
stoppingButtonTextW:.skip 128
confirmCleanTitleW:.skip 256
confirmCleanTextW:.skip 1024
pathTemplateW:    .skip 4096
pathBufferW:      .skip 4096
searchSpecW:      .skip 4096
scanPathStackW:   .skip 102400
findDataStack:    .skip 15360
pathBuffer:  .skip 4096
numberBuffer:.skip 32
sizeDecimalBuffer:.skip 4
progressNumberBuffer:.skip 32
progressBuffer:.skip 512
progressWide:.skip 1024
logBuffer:   .skip 65536
logWide:     .skip 131072
