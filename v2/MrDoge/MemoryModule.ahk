; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=128846
; Author: MrDoge

MemoryLoadLibrary(buf) {
    ; This Source Code Form is subject to the terms of the Mozilla Public
    ; License, v. 2.0. If a copy of the MPL was not distributed with this
    ; file, You can obtain one at https://mozilla.org/MPL/2.0/.
    ; Copyright (c) 2004-2015 by Joachim Bauch / mail@joachim-bauch.de
    ; https://www.joachim-bauch.de/tutorials/loading-a-dll-from-memory/
    ; https://github.com/fancycode/MemoryModule/blob/master/MemoryModule.c
    e_lfanew:=NumGet(buf,0x3c,"Int") ;IMAGE_DOS_HEADER::e_lfanew
    optionalSectionSize:=NumGet(buf,e_lfanew+0x38,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.SectionAlignment
    NumberOfSections:=NumGet(buf,e_lfanew+0x6,"uShort") ;IMAGE_NT_HEADERS::FileHeader.NumberOfSections
    SizeOfOptionalHeader:=NumGet(buf,e_lfanew+0x14,"uShort") ;IMAGE_NT_HEADERS::FileHeader.SizeOfOptionalHeader
    lastSectionEnd:=0
    section:=e_lfanew+0x18+SizeOfOptionalHeader,end:=section + 0x28*NumberOfSections
    while (section < end) {
        endOfSection:=NumGet(buf,section+0xc,"Uint") ;IMAGE_SECTION_HEADER::VirtualAddress
        SizeOfRawData:=NumGet(buf,section+0x10,"Uint") ;IMAGE_SECTION_HEADER::SizeOfRawData
        if (SizeOfRawData) {
            endOfSection += SizeOfRawData
        } else {
            endOfSection += optionalSectionSize
        }
        if (endOfSection > lastSectionEnd) {
            lastSectionEnd := endOfSection
        }
        section+=0x28
    }
    AlignValueUp(value, alignment) {
        return (value + alignment - 1) & ~(alignment - 1)
    }
    AlignValueDown(value, alignment) {
        return value & ~(alignment - 1)
    }
    SectionAlignment:=NumGet(buf,e_lfanew+0x38,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.SectionAlignment
    SizeOfImage:=NumGet(buf,e_lfanew+0x50,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.SizeOfImage
    alignedImageSize := AlignValueUp(SizeOfImage, SectionAlignment)
    ImageBase:=NumGet(buf,e_lfanew-A_PtrSize+0x38,"Ptr") ;IMAGE_NT_HEADERS::OptionalHeader.ImageBase
    code := DllCall("VirtualAlloc","Ptr",ImageBase,"Ptr",alignedImageSize,"Uint",0x00003000,"Uint",0x04,"Ptr") ;MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE
    if (!code) {
        code := DllCall("VirtualAlloc","Ptr",0,"Ptr",alignedImageSize,"Uint",0x00003000,"Uint",0x04,"Ptr") ;MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE
        if (!code) {
            throw "//try to allocate memory at arbitrary position failed"
        }
    }
    if ((((code) >> 32) < (((code + alignedImageSize)) >> 32))) {
        throw "//Memory block may not span 4 GB boundaries."
    }
    SizeOfHeaders:=NumGet(buf,e_lfanew+0x54,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.SizeOfHeaders
    headers := DllCall("VirtualAlloc","Ptr",code,"Ptr",SizeOfHeaders,"Uint",0x00001000,"Uint",0x04,"Ptr") ;MEM_COMMIT, PAGE_READWRITE
    DllCall("ntdll\memcpy","Ptr",headers,"Ptr",buf,"Ptr",SizeOfHeaders)

    NumPut("Ptr",code,headers,e_lfanew-A_PtrSize+0x38) ;IMAGE_NT_HEADERS::OptionalHeader.ImageBase

    ;CopySections START
    section:=e_lfanew+0x18+SizeOfOptionalHeader,end:=section + 0x28*NumberOfSections
    while (section < end) {

        SizeOfRawData:=NumGet(headers,section+0x10,"Uint") ;IMAGE_SECTION_HEADER::SizeOfRawData
        VirtualAddress:=NumGet(headers,section+0xc,"Uint") ;IMAGE_SECTION_HEADER::VirtualAddress
        if (!SizeOfRawData) {
            if (SectionAlignment > 0) {
                DllCall("VirtualAlloc","Ptr",code+VirtualAddress,"Ptr",SectionAlignment,"Uint",0x00001000,"Uint",0x04,"Ptr") ;MEM_COMMIT, PAGE_READWRITE
                ; Always use position from file to support alignments smaller
                ; than page size (allocation above will align to page size).
                dest:=code+VirtualAddress
                ; NOTE: On 64bit systems we truncate to 32bit here but expand
                ; again later when "PhysicalAddress" is used.
                NumPut("Uint",dest & 0xffffffff,headers,section+0x8) ;IMAGE_SECTION_HEADER::Misc.PhysicalAddress
                DllCall("ntdll\memset","Ptr",dest,"Int",0,"Ptr",SectionAlignment)
            }
            section+=0x28
            continue
        }

        DllCall("VirtualAlloc","Ptr",code+VirtualAddress,"Ptr",SizeOfRawData,"Uint",0x00001000,"Uint",0x04,"Ptr") ;MEM_COMMIT, PAGE_READWRITE
        ; Always use position from file to support alignments smaller
        ; than page size (allocation above will align to page size).
        dest:=code+VirtualAddress
        PointerToRawData:=NumGet(headers,section+0x14,"Uint") ;IMAGE_SECTION_HEADER::PointerToRawData
        DllCall("ntdll\memcpy","Ptr",dest,"Ptr",buf.Ptr+PointerToRawData,"Ptr",SizeOfRawData)
        ; NOTE: On 64bit systems we truncate to 32bit here but expand
        ; again later when "PhysicalAddress" is used.
        NumPut("Uint",dest & 0xffffffff,headers,section+0x8) ;IMAGE_SECTION_HEADER::Misc.PhysicalAddress
        section+=0x28
    }
    ;CopySections END

    locationDelta := code - ImageBase
    if (locationDelta) {
        ;PerformBaseRelocation START
        directory_BASERELOC := e_lfanew+4*A_PtrSize+0x90 ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC]
        directory_BASERELOC_VirtualAddress:=NumGet(headers,directory_BASERELOC+0x0,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].VirtualAddress

        relocation:=code + directory_BASERELOC_VirtualAddress
        while ((relocation_VirtualAddress:=NumGet(relocation,"Uint"))) {
            dest := code + relocation_VirtualAddress
            relocation_SizeOfBlock := NumGet(relocation,0x4,"Uint")
            ;relInfo := relocation IMAGE_SIZEOF_BASE_RELOCATION);
            ok:=0
            i:=relocation+8,end:=relocation+relocation_SizeOfBlock
            while (i < end) {
                relInfo:=NumGet(i,"UShort")
                info_type:=relInfo >> 12
                switch (info_type) {
                    case 3: ;IMAGE_REL_BASED_HIGHLOW
                        ; change complete 32 bit address
                        offset:=relInfo & 0xfff
                        patchAddrHL := dest + offset
                        NumPut("Uint",NumGet(patchAddrHL,"Uint")+locationDelta,patchAddrHL)
                    case 10: ;IMAGE_REL_BASED_DIR64
                        offset:=relInfo & 0xfff
                        patchAddr64 := dest + offset
                        NumPut("UInt64",NumGet(patchAddr64,"UInt64")+locationDelta,patchAddr64)
                }
                i+=2
            }
            relocation += relocation_SizeOfBlock
        }
        ;PerformBaseRelocation END
    }

    ;BuildImportTable START
    directory := e_lfanew+4*A_PtrSize+0x70 ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT]
    directory_Size:=NumGet(headers,directory+0x4,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].Size
    if (directory_Size) {
        directory_VirtualAddress:=NumGet(headers,directory+0x0,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress
        importDesc:=directory_VirtualAddress
        loop {
            importDesc_Name:=NumGet(code,importDesc+0xc,"Uint") ;IMAGE_IMPORT_DESCRIPTOR::Name
            if (!importDesc_Name) {
                break
            }
            handle := DllCall("LoadLibraryA","Ptr",code+importDesc_Name,"Ptr")

            importDesc_OriginalFirstThunk:=NumGet(code,importDesc+0x0,"Uint") ; IMAGE_IMPORT_DESCRIPTOR::OriginalFirstThunk
            importDesc_FirstThunk:=NumGet(code,importDesc+0x10,"Uint") ; IMAGE_IMPORT_DESCRIPTOR::FirstThunk
            funcRef := code + importDesc_FirstThunk
            if (importDesc_OriginalFirstThunk) {
                thunkRef := code + importDesc_OriginalFirstThunk
            } else {
                ; no hint table
                thunkRef := funcRef
            }
            while (thunkRef_dereferenced:=NumGet(thunkRef,"Ptr")) {
                if (thunkRef_dereferenced & (1<<(A_PtrSize<<3)-1)) {
                    NumPut("Ptr",DllCall("GetProcAddress","Ptr",handle,"Ptr",thunkRef_dereferenced & 0xffff,"Ptr"),funcRef)
                } else {
                    NumPut("Ptr",DllCall("GetProcAddress","Ptr",handle,"Ptr",code+thunkRef_dereferenced+2,"Ptr"),funcRef)
                }
                thunkRef+=A_PtrSize, funcRef+=A_PtrSize
            }

            importDesc+=0x14
        }
    }
    ;BuildImportTable END

    ;FinalizeSections START

    ;READ
    ;COPY
    ;loop (Length-1) {
    ;    READ
    ;    UPDATE
    ;        continue
    ;
    ;    PROTECT
    ;    COPY
    ;}
    ;PROTECT
    ;
    ;READ,(COPY,(READ,UPDATE)*,PROTECT)+
    ;
    ;possible:
    ;READ,UPDATE
    ;READ,UPDATE,PROTECT,COPY
    ;READ,COPY,PROTECT
    ;
    ;PROTECT:(i<=length) ? COPY : return
    ;COPY:(i<length) ? READ : ++i,PROTECT
    ;UPDATE:current_needs_to_be_copied ? PROTECT : ((i<length) ? READ : PROTECT)
    ;READ:(i==0) ? COPY : UPDATE

    ;ProtectionFlags:=[PAGE_NOACCESS,PAGE_EXECUTE,PAGE_READONLY,PAGE_EXECUTE_READ,PAGE_WRITECOPY,PAGE_EXECUTE_WRITECOPY,PAGE_READWRITE,PAGE_EXECUTE_READWRITE,]
    ProtectionFlags:=[0x01,0x10,0x02,0x20,0x08,0x80,0x04,0x40,]

    if (A_PtrSize==8) {
        ; "PhysicalAddress" might have been truncated to 32bit above, expand to
        ; 64bits again.
        imageOffset := code & 0xffffffff00000000
    } else {
        imageOffset := 0
    }

    section:=e_lfanew+0x18+SizeOfOptionalHeader,end:=section + 0x28*NumberOfSections -0x28
    start:=section
    FinalizeSections_label:
    while (section <= end) {
        PhysicalAddress:=NumGet(headers,section+0x8,"Uint") ;IMAGE_SECTION_HEADER::Misc.PhysicalAddress
        sectionAddress := PhysicalAddress | imageOffset
        alignedAddress := AlignValueDown(sectionAddress, SectionAlignment)

        sectionSize:=NumGet(headers,section+0x10,"Uint") ;IMAGE_SECTION_HEADER::SizeOfRawData
        section_Characteristics:=NumGet(headers,section+0x24,"Uint") ;IMAGE_SECTION_HEADER::Characteristics
        if (!sectionSize) {
            if (section_Characteristics & 0x00000040) { ;IMAGE_SCN_CNT_INITIALIZED_DATA
                sectionSize:=NumGet(headers,e_lfanew+0x20,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.SizeOfInitializedData
            } else if (section_Characteristics & 0x00000080) { ;IMAGE_SCN_CNT_UNINITIALIZED_DATA
                sectionSize:=NumGet(headers,e_lfanew+0x24,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.SizeOfUninitializedData
            }
        }

        loop {

            if (section == start) {
                sectionAddress_carry:=sectionAddress,alignedAddress_carry:=alignedAddress,sectionSize_carry:=sectionSize,section_Characteristics_carry:=section_Characteristics
                if (section < end) {
                    section+=0x28
                    continue FinalizeSections_label
                } else {
                    ++section ;will trigger break FinalizeSections_label
                }
            } else {
                ; Combine access flags of all sections that share a page
                ; TODO(fancycode): We currently share flags of a trailing large section
                ;   with the page of a first small section. This should be optimized.
                if (alignedAddress_carry == alignedAddress || sectionAddress_carry + sectionSize_carry > alignedAddress) {
                    ; Section shares page with previous
                    section_Characteristics_carry |= (section_Characteristics & 0xfdffffff) ;~IMAGE_SCN_MEM_DISCARDABLE
                    section_Characteristics_carry &= (section_Characteristics | 0xfdffffff) ;~IMAGE_SCN_MEM_DISCARDABLE

                    sectionSize_carry := sectionAddress + sectionSize - sectionAddress_carry
                    if (section < end) {
                        section+=0x28
                        continue FinalizeSections_label
                    }
                }
            }

            ;FinalizeSection START
            loop 1 {
                if (!sectionSize_carry) {
                    break
                }

                if (section_Characteristics_carry & 0x02000000) { ;IMAGE_SCN_MEM_DISCARDABLE
                    ; section is not needed any more and can safely be freed
                    if (sectionAddress_carry == alignedAddress_carry) {
                        ; Only allowed to decommit whole pages
                        DllCall("VirtualFree","Ptr",sectionAddress_carry,"Ptr",sectionSize_carry,"Uint",0x00004000) ;MEM_DECOMMIT
                    }
                    break
                }

                protect := ProtectionFlags[(section_Characteristics_carry >> 29)+1]
                if (section_Characteristics_carry & 0x04000000) { ;IMAGE_SCN_MEM_NOT_CACHED
                    protect |= 0x200 ;PAGE_NOCACHE
                }

                DllCall("VirtualProtect","Ptr",sectionAddress_carry,"Ptr",sectionSize_carry,"Uint",protect,"Uint*",&oldProtect:=0)
            }
            if (section > end) {
                break FinalizeSections_label
            }
            ;FinalizeSection END
            start:=section
        }
    }
    ;FinalizeSections END

    ;ExecuteTLS START
    directory_TLS := e_lfanew+4*A_PtrSize+0xb0 ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_TLS]
    directory_TLS_VirtualAddress:=NumGet(headers,directory_TLS+0x0,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_TLS].VirtualAddress
    if (directory_TLS_VirtualAddress) {
        tls := code + directory_TLS_VirtualAddress
        callback:=NumGet(tls,3*A_PtrSize,"Ptr") ;IMAGE_TLS_DIRECTORY::AddressOfCallBacks
        if (callback) {
            while (callback_dereferenced:=NumGet(callback,"Ptr")) {
                DllCall(callback_dereferenced,"Ptr",code,"Uint",1,"Ptr",0) ;DLL_PROCESS_ATTACH
                callback+=A_PtrSize
            }
        }
    }
    ;ExecuteTLS END

    ; get entry point of loaded library
    AddressOfEntryPoint:=NumGet(headers,e_lfanew+0x28,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.AddressOfEntryPoint
    FileHeader_Characteristics:=NumGet(buf,e_lfanew+0x16,"uShort") ;IMAGE_NT_HEADERS::FileHeader.Characteristics
    if (AddressOfEntryPoint) {
        if (FileHeader_Characteristics & 0x2000) { ;IMAGE_FILE_DLL
            DllEntry := code + AddressOfEntryPoint
            DllCall(DllEntry,"Ptr",code,"Uint",1,"Ptr",0) ;DLL_PROCESS_ATTACH
        }
    }

    GetProcAddress_map:=Map()
    directory_export := e_lfanew+4*A_PtrSize+0x68 ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT]
    directory_export_VirtualAddress:=NumGet(headers,directory_export+0x0,"Uint") ;IMAGE_NT_HEADERS::OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress
    exports:=code + directory_export_VirtualAddress

    nameRef:=code + NumGet(exports,0x20,"Uint") ;IMAGE_EXPORT_DIRECTORY::AddressOfNames
    ordinal:=code + NumGet(exports,0x24,"Uint") ;IMAGE_EXPORT_DIRECTORY::AddressOfNameOrdinals
    NumberOfNames:=NumGet(exports,0x18,"Uint") ;IMAGE_EXPORT_DIRECTORY::NumberOfNames
    AddressOfFunctions:=NumGet(exports,0x1c,"Uint") ;IMAGE_EXPORT_DIRECTORY::AddressOfFunctions
    end:=nameRef+4*NumberOfNames
    while (nameRef < end) {
        name:=StrGet(code + NumGet(nameRef,"Uint"),"UTF-8")
        GetProcAddress_map[name] := code + NumGet(code,AddressOfFunctions + NumGet(ordinal,"uShort")*4,"Uint")
        nameRef+=4,ordinal+=2
    }
    return GetProcAddress_map
}