# Introduction #

This page will give a general overview of where files are placed in the anzhelka project.


# Details #


```

/hardware
/frame
/pcb
/software
/spin
/src
/lib
/test
/tool
/config
/java
/src
/lib
/test
/tool
/config
/doc
/datasheet
/reports
/figures
/notes
/tests
/extra
/extra
```


## Hardware ##
Subfolders will store the major components of the project. For example, the frame has several .dxf files that are sent to the laser cutter, so that will all go into a subfolder called frame. The project may have several PCBs made as well, and so each should go into a subfolder under pcb.

## Software ##
The software is separated by language into separate folders. This makes sense because each processor in the project will have only one language running, but separate processors that are running the same language may share components (library files, for example). Each language has a number of subfolders:
  * src is where the source code for the project is stored. Subfolders as appropriate.
  * lib stores all general purpose library files (code) such as Propeller Obex objects.
  * test stores the test harnesses such as unit tests and Spin code to test a particular module (the latter case would have a 'main' type method and would be self supporting when running on the Propeller).
  * tool holds all the relevant development tools for that language (bstc for Spin, for example).
  * config stores any sort of relevant compile time or testing configuration files.

The files that are in the Software folder should be used only for what runs onboard the quadrotor. Test programs or desktop PC client programs should instead go into the Extra folder. Note that these programs may still access the lib and tool subfolders in the software directory.

## Documentation ##
This folder stores all the relevant datasheets in the datasheet subdirectory, and any other project documentation that is deemed to fit. Note that most documentation probably belongs in the anzhelka wiki.

The datasheet and reports folder contain the reference datasheets for each component and the various generated reports of the project, respectively. The figures folder holds an images that is used in the documentation. The notes folders holds papers that are interesting and relevant to the project, such as the cited research papers. The tests folder holds the test results data, and any associated data processing scripts. The extra folder holds other documentation material such as project logos and fonts.

## Extra ##
This folder contains other associated programs for the project. Since the Software folder is dedicated exclusively to software that is intended to fly the quadrotor other programs need to be stored in the Extra folder. This folder stores the Anzhelka Terminal files and the Thrust/Torque test stand files for example.