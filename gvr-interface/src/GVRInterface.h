//
//  GVRInterface.h
//  gvr-interface/src
//
//  Created by Stephen Birarda on 11/18/14.
//  Copyright 2013 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#ifndef hifi_GVRInterface_h
#define hifi_GVRInterface_h

#include <QtWidgets/QApplication>

class RenderingClient;

#if defined(qApp)
#undef qApp
#endif
#define qApp (static_cast<GVRInterface*>(QApplication::instance()))

class GVRInterface : public QApplication {
    Q_OBJECT
public:
    GVRInterface(int argc, char* argv[]);
      
    RenderingClient* getClient() { return _client; }
    
private:
    RenderingClient* _client;
};

#endif // hifi_GVRInterface_h
