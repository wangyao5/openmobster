/**
 * Copyright (c) {2003,2011} {openmobster@gmail.com} {individual contributors as indicated by the @authors tag}.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */

package org.openmobster.core.mobileCloud.android_native.framework;

import java.util.Timer;

import org.openmobster.core.mobileCloud.android.configuration.AppSystemConfig;
import org.openmobster.core.mobileCloud.android.configuration.Configuration;
import org.openmobster.core.mobileCloud.android.errors.ErrorHandler;
import org.openmobster.core.mobileCloud.android.errors.SystemException;
import org.openmobster.core.mobileCloud.android.kernel.DeviceContainer;
import org.openmobster.core.mobileCloud.android.service.Registry;
import org.openmobster.core.mobileCloud.android_native.framework.events.NativeEventBusSPI;
import org.openmobster.core.mobileCloud.api.ui.framework.Services;
import org.openmobster.core.mobileCloud.mgr.AppActivationService;
import org.openmobster.core.mobileCloud.spi.ui.framework.SPIServices;

import android.content.Context;
import android.app.Activity;
import android.os.Handler;
import android.os.Looper;

/**
 * @author openmobster@gmail.com
 *
 */
public class CloudService
{
	private static CloudService singleton;
	
	private CloudService()
	{
	}
	
	public static CloudService getInstance()
	{
		if(singleton == null)
		{
			synchronized(CloudService.class)
			{
				if(singleton == null)
				{
					singleton = new CloudService();
				}
			}
		}
	
		return singleton;
	}
			
	public void start(final Activity context)
	{
		try
		{
			//short-fast boostrapping of the kernel
			if(!DeviceContainer.getInstance(context.getApplicationContext()).isContainerActive())
			{
				this.bootstrapContainer(context);
			}
			
			//longer background services to be executed in a background thread to not hold up the App launch
			Thread t = new Thread(new Runnable()
			{
				public void run()
				{
					try
					{
						bootstrapApplication(context);
					}
					catch(Throwable e)
					{
						e.printStackTrace(System.out);
						ErrorHandler.getInstance().handle(new SystemException(this.getClass().getName(), "start", new Object[]{
							"Message:"+e.getMessage(),
							"Exception:"+e.toString()
						}));
						
						
						//Show a bootrstap error
						ShowErrorLooper looper = new ShowErrorLooper();
						looper.start();
						
						while(!looper.isReady());
						
						looper.handler.post(new ShowError(context));
					}
				}
			}
			);
			t.start();
		}
		catch(Throwable e)
		{
			e.printStackTrace(System.out);
			ErrorHandler.getInstance().handle(new SystemException(this.getClass().getName(), "start", new Object[]{
				"Message:"+e.getMessage(),
				"Exception:"+e.toString()
			}));
			
			ViewHelper.getOkModalWithCloseApp(context, "System Error", e.getMessage())
			.show();
		}
	}
	
	public void startContainer(final Activity context)
	{
		try
		{
			//short-fast boostrapping of the kernel
			if(!DeviceContainer.getInstance(context.getApplicationContext()).isContainerActive())
			{
				this.bootstrapContainer(context);
			}
		}
		catch(Throwable e)
		{
			e.printStackTrace(System.out);
			ErrorHandler.getInstance().handle(new SystemException(this.getClass().getName(), "start", new Object[]{
				"Message:"+e.getMessage(),
				"Exception:"+e.toString()
			}));
			
			ViewHelper.getOkModalWithCloseApp(context, "System Error", e.getMessage())
			.show();
		}
	}
	
	public void stop(final Context context)
	{
		
	}
	
	public void activateDevice(String server,int port, String email, String password) throws ServiceException
	{
		ServiceContext serviceContext = new ServiceContext();
		serviceContext.setAttribute("server", server);
		serviceContext.setAttribute("port", ""+port);
		serviceContext.setAttribute("email", email);
		serviceContext.setAttribute("password", password);
		
		
		AppActivationService.getInstance().activate(serviceContext);
	}
	
	public String getServer()
	{
		return AppSystemConfig.getInstance().getServer();
	}
	
	public String getPort()
	{
		return AppSystemConfig.getInstance().getPort();
	}
	
	public boolean isDeviceActivated()
	{
		Configuration conf = Configuration.getInstance(Registry.getActiveInstance().getContext());
		return conf.isActive();
	}
	//---------------------------------------------------------------------------------------------------------------------
	private void bootstrapContainer(final Activity context)
	{
		//Initialize some of the higher level services
		Services services = Services.getInstance();
		//Load API Services
		services.setResources(new NativeAppResources());
		services.setCommandService(new NativeCommandService());
		services.setCurrentActivity(context);
		
		//Load SPI Services
		SPIServices.getInstance().setNavigationContextSPI(new NativeNavigationContextSPI());
		SPIServices.getInstance().setEventBusSPI(new NativeEventBusSPI());
		
		//Initialize the kernel
		DeviceContainer container = DeviceContainer.getInstance(context.getApplicationContext());
		
		//start the kernel
		container.propagateNewContext(context.getApplicationContext());
    	container.startup();
	}
	
	private void bootstrapApplication(final Context context) throws Exception
	{
    	//Handle auto sync checking upon App launch, only if channels are not
    	//being initialized
    	Timer timer = new Timer();
		timer.schedule(new BackgroundSync(), 
		5000);
	}
	
	private class ShowErrorLooper extends Thread
	{
		private Handler handler;
		
		private ShowErrorLooper()
		{
			
		}
		
		public void run()
		{
			Looper.prepare();
			
			this.handler = new Handler();
			
			Looper.loop();
		}
		
		public boolean isReady()
		{
			return this.handler != null;
		}
	}
	
	private class ShowError implements Runnable
	{
		private Activity currentActvity;
		public ShowError(Activity currentActivity)
		{
			this.currentActvity = currentActivity;
		}
		
		public void run()
		{
			ViewHelper.getOkModalWithCloseApp(this.currentActvity, "System Error", "An unknown error occurred during App startup. Please try again")
			.show();
			
			Looper.myLooper().quit();
		}
	}
}
