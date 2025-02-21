import { Global, Module } from '@nestjs/common';
import { NotificationService } from './services/notification.service';
import { NotificationController } from './controllers/notification.controller';
import { CategoryService } from '../category/services/category.service';
import { UsersService } from 'src/users/users.service';

@Global()
@Module({
  controllers: [NotificationController],
  providers: [NotificationService, CategoryService, UsersService],
  imports: [],
})
export class NotificationModule {}
